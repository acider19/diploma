# Дипломный проект: DevOps-инфраструктура в Yandex Cloud

Учебный проект по курсу «DevOps-инженер» (Netology). Инфраструктура, кластер
Kubernetes, мониторинг и CI/CD полностью описаны кодом и разворачиваются с нуля.

> **Статус:** код инфраструктуры, приложения и пайплайнов готов. Развёртывание
> приостановлено из-за квот облака: в текущем каталоге доступно 10 ГБ SSD и
> закрыта зона `ru-central1-a`. Что запросить — см. [docs/quota.md](docs/quota.md).

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
 ├─ 1 master + 2 worker   — Kubespray, worker-ноды preemptible
 └─ NLB                   — публичный вход на 80/443
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
- [x] Terraform: master + worker-ноды (preemptible), NLB, DNS-зона (опционально)
- [x] Ansible/Kubespray: установка K8s 1.31, Calico, IPVS
- [x] Приложение: nginx unprivileged, Dockerfile, Helm-чарт с PDB и пробами
- [x] Мониторинг: values для kube-prometheus-stack и ingress-nginx
- [x] CI/CD: Terraform plan/apply, сборка по коммиту, деплой по тегу
- [ ] Развернуть кластер (блокирует квота — см. `docs/quota.md`)
- [ ] Подключить домен и HTTPS (после регистрации домена)
- [ ] Снять скриншоты для защиты

## Секреты GitHub Actions

| Secret | Назначение |
|---|---|
| `YC_SA_KEY_JSON` | Ключ сервисного аккаунта (полный JSON) |
| `YC_STORAGE_ACCESS_KEY` / `YC_STORAGE_SECRET_KEY` | Static key для S3 backend |
| `KUBECONFIG_B64` | `base64 -i ~/.kube/config` |

Переменные репозитория: `APP_HOST` (например `app.example.com`),
`APP_TLS_ENABLED` (`true` после настройки cert-manager).
