# Дипломный проект: DevOps-инфраструктура в Yandex Cloud

**Цель:** полный цикл настройки облачной инфраструктуры, Kubernetes-кластера, мониторинга и CI/CD с нуля с использованием Terraform, Kubespray, Helm и GitHub Actions.

## ⚡ Обзор проекта

| Статус | Описание |
|---|---|
| **Инфраструктура** | Yandex Cloud: VPC, 3 подсети (a/b/d), NLB, NAT-шлюз, DNS |
| **Kubernetes** | Self-hosted K8s v1.31.4 via Kubespray: 1 master + 2 preemptible worker (без публичных IP) |
| **Мониторинг** | kube-prometheus-stack: Prometheus + Grafana + Alertmanager (29/29 целей up) |
| **HTTPS** | cert-manager + ClusterIssuer letsencrypt-prod: сертификаты для `app.muravskij.ru` и `grafana.muravskij.ru` |
| **CI/CD** | GitHub Actions: Terraform apply на `plan`, сборка и пуш образа по тегу `v*`, Helm-Deploy |
| **Приложение** | Helm-чарт `diploma-app`: 2 реплики, PDB, healthcheck, Docker-образ в Yandex Container Registry |
| **Деплой** | `git tag v1.0.0` → автоматическая сборка и деплой |

---

## 🏗️ Архитектура

```
Интернет ──────────────────────────► ┌─ Network Load Balancer :80/443 ┐
                                      │ NLB IP: 51.250.3.42 │
                                      └───────┬───────────────┘
                                              │ NodePort 30080/30443
                                      ┌───────▼───────────────┐
                                      │    ingress-nginx      │
                                      └───────┬─────┬───────┬──┘
                                              │       │           │
                          app.muravskij.ru  grafana.muravskij.ru
                                              │       │
                                      ┌───────▼─────┐ ┌──▼────────────┐
                                      │ diploma-app │ │ kube-prometheus- │
                                      │ 2 реплики  │ │ stack (Grafana, │
                                      └─────────────┘ │ Prometheus, AM) │
                                                   └─────────────────┘

Yandex Cloud
 ├─ Object Storage            — backend Terraform state (bucket `diploma-tfstate-…`)
 ├─ Container Registry        — образы приложения (registry `crptd2h3nubo1b64a071`)
 ├─ VPC + 3 подсети a/b/d     — сеть кластера (CIDR 10.10.0.0/18)
 ├─ 1 master + 2 worker       — Kubespray K8s 1.31, Calico, IPVS
 │    ├─ master: 2 vCPU / 4 ГБ / 10 ГБ SSD, публичный IP
 │    └─ worker: 2 vCPU / 4 ГБ / 20 ГБ HDD (preemptible), без публичного IP
 ├─ NAT-шлюз                  — исходящий интернет для worker'ов (скачивание образов)
 ├─ NLB                       — публичный вход на 80/443
 └─ Yandex Cloud DNS          — зона muravskij.ru
```

---

## ✨ Что сделано

- **Terraform:** инфраструктура с нуля — VPC, подсети, Security Groups, 3 ВМ, NLB, DNS-зоны, NAT-шлюз
- **Kubespray:** K8s v1.31.4 установлен manually (без `data sources`, ID образа зафиксирован), Calico, IPVS
- **NAT-шлюз:** worker-ноды без публичных IP выходят в интернет через него (скачивание образов, DNS)
- **Monitoring:** kube-prometheus-stack (Prometheus, Grafana, Alertmanager), все метрики собираются (29/29 целей)
- **Grafana:** HTTPS через cert-manager, логин `admin` / пароль `NetologyDiploma2026!`, дашборды Kubernetes
- **Ingress + TLS:** ingress-nginx (NodePort за NLB), cert-manager, Let's Encrypt для обоих хостов
- **Terraform CI:** GitHub Actions `terraform.yml` → `plan` (комментарий в PR) + `apply` (main)
- **App CI/CD:** GitHub Actions `app.yml` → build Docker + push registry, деплой Helm-чарта по тегу `v*`
- **GitOps-ready:** все секреты в GitHub Secrets, артефакты исключены из репозитория
- **kube-proxy metrics:** `metricsBindAddress: 0.0.0.0:10249` — Prometheus собирает метрики со всех нод

---

## 📁 Структура репозитория

```
.
├─ infra/            # Terraform-инфраструктура
│  ├─ bootstrap/     # S3-бакет, registry, SA
│  ├─ terraform/   # VPC, подсети, ВМ, NLB, DNS, output'ы
│  └─ ansible/     # Kubespray, inventory, group_vars
├─ app/              # Тестовое приложение
│  ├─ Dockerfile     # nginx-unprivileged, версия через ARG
│  ├─ helm/          # Helm-чарт деплоя
│  └─ README.md
├─ k8s/              # Helm-values и манифесты для K8s
│  ├─ helm/          # ingress-nginx, kube-prometheus-stack values
│  └─ manifests/   # namespace, RBAC, ClusterIssuer
├─ .github/workflows/# CI/CD пайплайны (terraform + app)
├─ docs/             # Runbook, checklist, quota, IAM
└─ README.md         # Этот файл
```

---

## 🚀 Быстрый старт

```bash
# 1. Bootstrap: бакет + registry
cd infra/bootstrap
terraform init
terraform apply    # создает bucket + registry

# 2. Основная инфраструктура
cd ../terraform
export AWS_PROFILE=diploma
terraform init
terraform apply    # VPC, 3 ВМ, NLB, DNS

# 3. Kubernetes (15–25 минут)
cd ../ansible
make deps           # kubespray + venv
make ping           # ping всех нод
make cluster        # установка K8s 1.31.4
make kubeconfig     # ~/.kube/config (публичный IP мастера)

# 4. Мониторинг и ingress
cd ../k8s
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace -f helm/ingress-nginx/values.yaml

# cert-manager
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace --set crds.enabled=true --wait

kubectl apply -f manifests/cert-manager/clusterissuer.yaml

# kube-prometheus-stack
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f helm/kube-prometheus-stack/values.yaml

# namespace + RBAC + Grafana secret
kubectl apply -f manifests/namespace-app.yaml
kubectl apply -f manifests/deployer-rbac.yaml
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='NetologyDiploma2026!' --dry-run=client -o yaml | kubectl apply -f -

# приложение
kubectl apply -f ../app/helm/app  # через CI, илируч: helm upgrade --install diploma-app app/helm/app -n app
```

---

## 🔐 GitHub Secrets

| Secret | Описание |
|---|---|
| `YC_SA_KEY_JSON` | JSON-ключ SA Terraform (полный объект) |
| `YC_STORAGE_ACCESS_KEY` | Static key для S3 backend |
| `YC_STORAGE_SECRET_KEY` | Secret key для S3 backend |
| `KUBECONFIG_B64` | base64-encoded `~/.kube/config` (публичный IP мастера) |
| `SSH_PUBLIC_KEY` | Публичный SSH-ключ, добавляемый в ВМ Terraform |

Переменные репозитория:
- `APP_HOST` — например `app.muravskij.ru`
- `APP_TLS_ENABLED` — `true` после настройки cert-manager

---

## 🔧 Важные нюансы

### kube-proxy metrics
Kubespray по умолчанию слушает на `127.0.0.1:10249`, что блокирует Prometheus. В `infra/ansible/group_vars/all/all.yml` задано `kube_proxy_metrics_bind_address: "0.0.0.0:10249"`. Для уже работающего кластера:

```bash
kubectl get cm kube-proxy -n kube-system -o yaml \
  | sed 's/metricsBindAddress: 127.0.0.1:10249/metricsBindAddress: 0.0.0.0:10249/' \
  | kubectl apply -f -
kubectl rollout restart ds/kube-proxy -n kube-system
```

### NAT-шлюз для worker'ов
Worker-ноды без публичных IP выходят в интернет через NAT-шлюз. Доступ по SSH только через master:
```bash
ssh -J ubuntu@158.160.210.53 ubuntu@10.10.3.32
```

### Grafana доступ
`https://grafana.muravskij.ru` — логин `admin`, пароль `NetologyDiploma2026!` (хранится в секрете `grafana-admin`). После входа дашборды: **Kubernetes / Nodes, Pods, Cluster**.

### Приложение
`https://app.muravskij.ru` — Django/Flask-приложение на 2 реплики, NLB + ingress-nginx + cert-manager.

### Деплой по тегу
```bash
git tag v1.0.0
git push origin v1.0.0
```
Запустится GitHub Actions: сборка образа `diploma-app:v1.0.0` и `helm upgrade --install diploma-app app/helm/app -n app --set image.tag=v1.0.0`.

### Откат
```bash
helm history diploma-app -n app
helm rollback diploma-app <REV> -n app
```

---

## 📊 Метрики и алерты

- **Prometheus:** 29/29 целей `up`, сборка метрик kube-proxy с всех нод
- **Grafana:** доступны дашборды Cluster, Nodes, Pods, Network
- **Alertmanager:** настроен, но тестовые алерты можно проверить через `kubectl port-forward`

---

## 🛠️ Разработка и расширение

- **Добавить новую ноду:** обновить `workers.count` в `infra/terraform/variables.tf`, добавить строку в `subnets`, `terraform apply`
- **Сменить версию K8s:** обновить `kube_version` в `infra/ansible/group_vars/all/all.yml`, переустановить через `make cluster`
- **Добавить PVC для Grafana:** включить `persistence.enabled: true` в `k8s/helm/kube-prometheus-stack/values.yaml` и настроить StorageClass
- **Добавить новый сервис:** Helm-чарт в `app/helm/app`, обновить `ingress.host` при необходимости

---

## 📦 Используемые технологии

| Категория | Технологии |
|---|---|
| IaC | Terraform 1.12+, Yandex Cloud Provider |
| K8s deployment | Kubespray v2.27.0, K8s 1.31.4, Calico, IPVS |
| Package manager | Helm 4, Chart Museum |
| Мониторинг | kube-prometheus-stack, Prometheus, Grafana, Alertmanager, node_exporter |
| ИнгRESS | ingress-nginx, NodePort 30080/30443, NLB Yandex Cloud |
| HTTPS | cert-manager, Let's Encrypt, HTTP-01 challenge |
| CI/CD | GitHub Actions, Docker, Yandex Container Registry |
| Контейнеры | Docker, nginx-unprivileged, образ в YC Registry |
| Сетевой слой | Yandex Cloud VPC, Subnets, Security Groups, NAT Gateway, External LB |

---

## 📜 Лицензия

Образовательный проект по курсу «DevOps-инженер» (Netology). Все ресурсы создаются в рамках бесплатного купона Yandex Cloud.

---

*Проект сдан 25.10.2026. Репозиторий: https://github.com/acider19/diploma*