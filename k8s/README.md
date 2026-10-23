# Kubernetes-конфигурация дипломного проекта

Здесь лежат Helm-values и манифесты для self-hosted кластера, собранного
Kubespray (см. `infra/ansible`).

## Порядок установки

```bash
# 1. ingress-nginx (NodePort 30080/30443, наружу смотрит NLB из Terraform)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f helm/ingress-nginx/values.yaml

# 2. cert-manager (для HTTPS после подключения домена)
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true
kubectl apply -f manifests/cert-manager/clusterissuer.yaml

# 3. Namespace и RBAC для деплоя из CI
kubectl apply -f manifests/namespace-app.yaml
kubectl apply -f manifests/deployer-rbac.yaml

# 4. Секрет Grafana (пароль заменить)
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<пароль>' --dry-run=client -o yaml | kubectl apply -f -

# 5. Мониторинг
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f helm/kube-prometheus-stack/values.yaml
```

Приложение ставится из чарта `app/helm/app` (репозиторий приложения) командой
`helm upgrade --install` — это делает CI при создании тега.

## Адреса

- приложение: `http://app.<домен>` (и `https://` после включения TLS);
- Grafana: `http://grafana.<домен>`;
- NLB: IP выдаёт Terraform output `nlb_ip`.
