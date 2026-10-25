# Дипломный проект: DevOps-инфраструктура в Yandex Cloud

Учебный проект по курсу «DevOps-инженер» (Netology). Инфраструктура, кластер
Kubernetes, мониторинг и CI/CD полностью описаны кодом и разворачиваются с нуля.

> **Статус:** инфраструктура развёрнута в Yandex Cloud, Kubernetes-кластер поднят
> через Kubespray (1 master + 2 worker), установлен ingress-nginx и
> kube-prometheus-stack, тестовое приложение и Grafana доступны через домен
> `muravskij.ru`. CI/CD настроен через GitHub Actions.

## Архитектура

```
                        ┌──────────────────────────────┐
   Интернет ───────────►│  Network Load Balancer :80/443│
                        └──────────────┬───────────────┘
                                       │ NodePort 30080/30443
                        ┌──────────────▼───────────────┐
                        │        ingress-nginx         │
                        └───┬──────────┬───────────┬───┘
                            │          │           │
                  app.<домен>   grafana.<домен>  alertmanager.<домен>
                            │          │
                  ┌─────────▼──┐  ┌────▼──────────────┐
                  │ diploma-app│  │ kube-prometheus-  │
                  │ 2 реплики  │  │ stack (Grafana,   │
                  └────────────┘  │ Prometheus, AM)   │
                                  └───────────────────┘

Yandex Cloud
 ├─ Object Storage        — backend Terraform state
 ├─ Container Registry    — образы приложения (создаётся Terraform)
 ├─ VPC + 3 подсети a/b/d — сеть кластера
 ├─ 1 master + 2 worker   — Kubespray, worker-ноды preemptible и без публичных IP
 ├─ NLB                   — публичный вход на 80/443
 └─ Yandex Cloud DNS      — зона muravskij.ru
```

## Структура репозитория

| Путь | Назначение |
|---|---|
| `infra/bootstrap` | Сервисный аккаунт, S3-бакет для state, Container Registry |
| `infra/terraform` | VPC, подсети, security groups, ВМ, NLB, DNS |
| `infra/ansible` | Inventory и установка Kubernetes через Kubespray |
| `app` | nginx-приложение, Dockerfile, Helm-чарт |
| `k8s` | Helm-values мониторинга и ingress, RBAC для CI |
| `.github/workflows` | Terraform pipeline и CI/CD приложения |
| `docs` | IAM, квоты, runbook, чек-лист защиты |

Каждая директория самодостаточна: `infra`, `app` и `k8s` можно вынести в
отдельные репозитории (`docs/split-repos.md`).

## Быстрый старт

```bash
# 1. Bootstrap: бакет state + registry (локальный state)
cd infra/bootstrap
terraform init
terraform apply

# 2. Основная инфраструктура (state в S3)
cd ../terraform
export AWS_PROFILE=diploma
terraform init
terraform apply

# 3. Kubernetes
cd ../ansible
make deps && make ping && make cluster && make kubeconfig

# 4. Мониторинг и ingress
cd ../../k8s
# команды — в k8s/README.md
```

## Что уже сделано

- [x] Bootstrap: S3-бакет `diploma-tfstate-*`, Container Registry `diploma-app`
- [x] VPC `diploma-net`, 3 подсети, security groups
- [x] Terraform: 1 master + 2 worker (preemptible), NLB, DNS-зона в Yandex Cloud DNS
- [x] Ansible/Kubespray: установка K8s 1.31, Calico, IPVS
- [x] Приложение: nginx unprivileged, Dockerfile, Helm-чарт с PDB и пробами
- [x] Мониторинг: kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
- [x] Ingress: ingress-nginx (NodePort 30080/30443 за NLB)
- [x] Домен: `muravskij.ru` делегирован в Yandex Cloud DNS
- [x] CI/CD: Terraform plan/apply, сборка образа по коммиту, деплой по тегу `v*`
- [ ] HTTPS/cert-manager (после полной прокатки делегирования)
- [ ] Снять скриншоты для защиты

## Секреты GitHub Actions

| Secret | Назначение |
|---|---|
| `YC_SA_KEY_JSON` | Ключ сервисного аккаунта (полный JSON) |
| `YC_STORAGE_ACCESS_KEY` / `YC_STORAGE_SECRET_KEY` | Static key для S3 backend |
| `KUBECONFIG_B64` | `base64 -i ~/.kube/config` |
| `SSH_PUBLIC_KEY` | Публичный SSH-ключ, который Terraform прописывает в ВМ |

Переменные репозитория: `APP_HOST` (например `app.muravskij.ru`),
`APP_TLS_ENABLED` (`true` после настройки cert-manager).
