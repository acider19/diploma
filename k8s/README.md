# Kubernetes-конфигурация дипломного проекта

Здесь лежат Helm-values и манифесты для self-hosted кластера, собранного
Kubespray (см. `infra/ansible`).

## Порядок установки

Порядок важен: `kube-prometheus-stack` приносит CRD `monitoring.coreos.com`,
без которых не ставится `ingress-nginx` — в его values включён ServiceMonitor.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 1. Namespace и RBAC для деплоя из CI
kubectl apply -f manifests/namespace-app.yaml
kubectl apply -f manifests/deployer-rbac.yaml

# 2. cert-manager и ClusterIssuer letsencrypt-prod
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --version v1.21.3 \
  --set crds.enabled=true --wait

# 3. Секрет Grafana
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<пароль>' --dry-run=client -o yaml | kubectl apply -f -

# 4. Мониторинг (ставит CRD monitoring.coreos.com)
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --version 92.13.1 \
  -f helm/kube-prometheus-stack/values.yaml --wait --timeout 20m

# 5. ingress-nginx: NodePort 30080/30443, наружу смотрит NLB из Terraform
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace --version 4.15.1 \
  -f helm/ingress-nginx/values.yaml --wait

# 6. ClusterIssuer (после ingress-nginx: HTTP-01 проходит через него)
kubectl apply -f manifests/cert-manager/clusterissuer.yaml
kubectl wait --for=condition=Ready clusterissuer/letsencrypt-prod --timeout=180s
```

Приложение ставится из чарта `app/helm/app` командой `helm upgrade --install` —
это делает CI при создании тега `v*`.

## Метрики kube-proxy

Kubespray по умолчанию слушает метрики kube-proxy на `127.0.0.1:10249`, из-за
чего Prometheus не может их собрать. В `infra/ansible/group_vars/all/all.yml`
задано `kube_proxy_metrics_bind_address: "0.0.0.0:10249"`. Для уже работающего
кластера конфигурация правится в ConfigMap и kube-proxy перезапускается:

```bash
kubectl get cm kube-proxy -n kube-system -o yaml \
  | sed 's/metricsBindAddress: 127.0.0.1:10249/metricsBindAddress: 0.0.0.0:10249/' \
  | kubectl apply -f -
kubectl rollout restart ds/kube-proxy -n kube-system
```

## Адреса

- приложение: `https://app.muravskij.ru` (HTTP на 80 порту отвечает 308 на HTTPS);
- Grafana: `https://grafana.muravskij.ru`;
- NLB: IP выдаёт Terraform output `nlb_ip`.

Сертификаты Let's Encrypt выпускаются автоматически для обоих хостов через
ClusterIssuer `letsencrypt-prod` и ingress-nginx (HTTP-01).
