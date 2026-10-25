# Инфраструктура

Две независимые конфигурации Terraform и установка кластера Ansible.

## bootstrap/

Создаёт «фундамент», без которого не работает основная конфигурация:

- сервисный аккаунт (используется существующий, см. `docs/iam.md`);
- S3-бакет `diploma-tfstate-b1g68t7p4rjq035vq0o9` для remote state;
- Container Registry `diploma-app`.

State локальный, потому что бакета ещё не существует. Порядок запуска:

```bash
terraform init && terraform apply
```

## terraform/

Основная инфраструктура, state в S3:

- VPC `diploma-net` и подсети в `ru-central1-a/b/d`;
- security groups (SSH, API 6443, 80/443, NodePort);
- master (2 vCPU/4 ГБ, SSD 10 ГБ) с публичным IP и worker-ноды
  (preemptible, без NAT — доступ через master как bastion);
- внешний NLB на 80/443 → NodePort 30080/30443;
- DNS-зона и записи (опционально, `manage_dns = true`).

Перед запуском нужен профиль `diploma` в `~/.aws/credentials`:

```bash
export AWS_PROFILE=diploma
terraform init && terraform apply
```

Terraform генерирует `../ansible/inventory.ini`.

## ansible/

Установка Kubernetes через Kubespray, подробности — в `ansible/README.md`.
