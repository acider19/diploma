# Runbook: развёртывание с нуля

## 0. Предварительные требования

- `terraform` ≥ 1.9, `yc`, `ansible`, `kubectl`, `helm`, `docker`, `jq`;
- SSH-ключ `~/.ssh/id_ed25519` (публичная часть подставляется в ВМ);
- профиль `diploma` в `~/.aws/credentials` для S3 backend;
- ключ сервисного аккаунта в `YC_SERVICE_ACCOUNT_KEY_FILE`;
- квоты: ≥ 60 ГБ HDD, ≥ 6 vCPU в зоне (см. `quota.md`).
- публичный IP нужен только master и NLB, worker-ноды живут без NAT.

## 1. Bootstrap

```bash
cd infra/bootstrap
terraform init
terraform apply
```

Создаются: S3-бакет `diploma-tfstate-b1g68t7p4rjq035vq0o9`, registry
`diploma-app`. State bootstrap локальный — бакета ещё нет.

## 2. Инфраструктура

```bash
cd infra/terraform
export AWS_PROFILE=diploma
terraform init
terraform apply
terraform output
```

Появятся 3 ВМ (master + 2 worker), NLB и `infra/ansible/inventory.ini`.

## 3. Kubernetes

```bash
cd infra/ansible
make deps
make ping
make cluster          # 15–25 минут
make kubeconfig
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

## 4. Ingress и мониторинг

```bash
cd k8s
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace -f helm/ingress-nginx/values.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<пароль>' --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring -f helm/kube-prometheus-stack/values.yaml

kubectl apply -f manifests/namespace-app.yaml
kubectl apply -f manifests/deployer-rbac.yaml
```

Дашборды Grafana приезжают вместе с чартом (sidecar), доступ — по ingress.

## 5. Домен и HTTPS

1. Делегировать домен на NS Яндекса.
2. В `infra/terraform/terraform.tfvars`: `manage_dns = true`, `domain_name = "<домен>"`.
3. `terraform apply` — появятся A-записи `app` и `grafana` на IP NLB.
4. Установить cert-manager и ClusterIssuer:

```bash
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true
# в clusterissuer.yaml заменить email
kubectl apply -f k8s/manifests/cert-manager/clusterissuer.yaml
```

5. Обновить values приложения и Grafana: `ingress.tls.enabled=true`,
   `clusterIssuer=letsencrypt-prod`.

## 6. GitHub Actions

Секреты: `YC_SA_KEY_JSON`, `YC_STORAGE_ACCESS_KEY`, `YC_STORAGE_SECRET_KEY`,
`KUBECONFIG_B64`. Переменные: `APP_HOST`, `APP_TLS_ENABLED`.

Проверка:

```bash
# Terraform pipeline
git checkout -b infra/check && touch infra/terraform/.keep
git commit -am "test terraform pipeline" && git push -u origin infra/check
# открыть PR, увидеть комментарий с планом, смержить

# Приложение
git tag v1.0.0 && git push origin v1.0.0
kubectl get pods -n app -w
```

## 7. Снос

```bash
cd infra/ansible && make reset   # сбросить кластер (опционально)
cd ../terraform && terraform destroy
cd ../bootstrap && terraform destroy
```

`terraform destroy` основной конфигурации удаляет ВМ, NLB и сеть; бакет и
registry удаляются на шаге bootstrap (registry должен быть пустым).
