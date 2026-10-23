# IAM и сервисные аккаунты

## Текущее состояние

Terraform запускается под сервисным аккаунтом `terraform-yc`
(`ajel1ja5vh6ci7clq840`) с ролью `editor` на каталог. Это не суперпользователь
(нет прав на облако и организацию), но роль широкая.

Создать отдельный сервисный аккаунт с гранулярными правами текущим ключом
нельзя: выдача ролей требует `iam.serviceAccounts.admin`, а операция
`add-access-binding` возвращает `Permission denied`. Поэтому SA создаётся
владельцем облака в консоли (или через `yc` под OAuth-аккаунтом).

## Минимальный набор ролей для Terraform

| Роль | Зачем |
|---|---|
| `compute.admin` | ВМ, диски, образы |
| `vpc.admin` | Сети, подсети, security groups |
| `load-balancer.admin` | Network Load Balancer и target group |
| `storage.admin` | Бакет для tfstate |
| `container-registry.admin` | Registry и права на образы |
| `dns.admin` | DNS-зона и записи (если домен в Yandex DNS) |
| `iam.serviceAccounts.user` | Использовать SA на нодах |

Для managed Kubernetes дополнительно нужен `k8s.admin`.

## Как создать выделенный SA (под владельцем облака)

```bash
FOLDER=b1g2ett5h4qn2kbsh6gr

yc iam service-account create --name diploma-terraform
SA_ID=$(yc iam service-account get diploma-terraform --format json | jq -r .id)

for role in compute.admin vpc.admin load-balancer.admin storage.admin \
            container-registry.admin dns.admin iam.serviceAccounts.user; do
  yc resource-manager folder add-access-binding "$FOLDER" \
    --role "$role" --subject "serviceAccount:$SA_ID"
done

yc iam key create --service-account-id "$SA_ID" -o diploma-terraform-key.json
```

Затем заменить `terraform_sa_id` в `infra/bootstrap/terraform.tfvars` и
положить ключ в GitHub Secrets как `YC_SA_KEY_JSON`.

## Ключ для S3 backend

Terraform S3 backend принимает только статические ключи, поэтому для SA создан
access key:

```bash
yc iam access-key create --service-account-id <SA_ID> --description "tfstate"
```

Ключ хранится локально в профиле `diploma` файла `~/.aws/credentials` и в
GitHub Secrets (`YC_STORAGE_ACCESS_KEY`, `YC_STORAGE_SECRET_KEY`).
