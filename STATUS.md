# Статус проекта

Обновлено: 23.10.2026.

Кратко: код инфраструктуры, приложения и CI/CD готов и запушен в GitHub.
В облаке созданы сеть, master и один worker, сетевой балансировщик.
Кластер Kubernetes ещё не установлен. Полноценные 3 ноды блокирует квота
на vCPU (доступно 4, нужно минимум 6).

## Что сделано

### Инфраструктура (Terraform)

- [x] Bootstrap (`infra/bootstrap`): S3-бакет для state
      `diploma-tfstate-b1g68t7p4rjq035vq0o9`, Container Registry
      `diploma-app` (`crptd2h3nubo1b64a071`).
- [x] Remote state основной конфигурации в S3, ключ `env/terraform.tfstate`.
- [x] VPC `diploma-net` и три подсети: `10.10.1.0/24` (a), `10.10.2.0/24` (b),
      `10.10.3.0/24` (d).
- [x] Security group `diploma-k8s`: SSH с домашнего IP, API 6443, 80/443,
      NodePort 30080–30443, весь внутренний трафик.
- [x] ВМ: `diploma-master` (2 vCPU / 4 ГБ / 10 ГБ SSD) и
      `diploma-worker-1` (2 vCPU / 4 ГБ / 20 ГБ HDD, preemptible) в зоне
      `ru-central1-d`.
- [x] Внешний NLB `diploma-ingress`: 80 → 30080, 443 → 30443,
      IP **51.250.3.42**.
- [x] Генерация `infra/ansible/inventory.ini` из Terraform.
- [x] DNS-зона и записи написаны, но выключены (`manage_dns = false`),
      пока нет домена.

### Kubernetes (Ansible)

- [x] Конфигурация Kubespray v2.27.0, Kubernetes v1.31.4, Calico, IPVS.
- [x] `Makefile`: `deps`, `ping`, `cluster`, `kubeconfig`, `reset`.
- [x] Inventory для master + worker-1 сгенерирован.
- [ ] Сам кластер ещё не установлен (`make deps` / `make cluster` не запускались).

### Приложение

- [x] nginx unprivileged, статическая страница `app/site/index.html`.
- [x] Dockerfile собирается, контейнер отвечает `200`, отдаёт версию.
- [x] Helm-чарт: Deployment (2 реплики), Service, Ingress, PDB,
      ServiceAccount, securityContext, пробы.
- [x] `helm lint` и `helm template` проходят.

### Kubernetes-конфигурация

- [x] Values для ingress-nginx (NodePort 30080/30443).
- [x] Values для kube-prometheus-stack (Prometheus, Grafana, Alertmanager,
      node-exporter, kube-state-metrics; без PVC, emptyDir).
- [x] Namespace `app` с Pod Security Standard `restricted`.
- [x] RBAC деплоера, ограниченный namespace `app`.
- [x] Пример секрета Grafana и ClusterIssuer Let's Encrypt.

### CI/CD

- [x] `.github/workflows/terraform.yml`: fmt, validate, plan, комментарий
      с планом в PR, apply на main.
- [x] `.github/workflows/app.yml`: сборка и push образа по коммиту, деплой
      в кластер по тегу `v*`.
- [x] `actionlint` проходит без ошибок.

### Документация

- [x] `README.md`, `docs/iam.md`, `docs/quota.md`, `docs/runbook.md`,
      `docs/defense-checklist.md`, `docs/split-repos.md`, README в
      `infra/`, `app/`, `k8s/`.
- [x] Коммиты запушены в `https://github.com/acider19/diploma`.

## Что реально развёрнуто в облаке

| Ресурс | Значение |
|---|---|
| Каталог | `b1g2ett5h4qn2kbsh6gr` |
| Зона | `ru-central1-d` |
| Master | `diploma-master`, 2 vCPU / 4 ГБ / 10 ГБ SSD, `130.193.57.194` |
| Worker | `diploma-worker-1`, 2 vCPU / 4 ГБ / 20 ГБ HDD, preemptible, `178.154.212.185` |
| NLB | `51.250.3.42`, 80 → 30080, 443 → 30443 |
| Registry | `cr.yandex/crptd2h3nubo1b64a071` |
| State | S3 `diploma-tfstate-b1g68t7p4rjq035vq0o9`, ключ `env/terraform.tfstate` |

## Проблемы и блокеры

### 1. Квота vCPU — главный блокер (3 ноды невозможны)

В зоне `ru-central1-d` доступно **4 vCPU**, уже заняты master + worker-1.
Третья ВМ требует ещё 2 ядра, поэтому создание падает с ошибкой
`The limit on maximum number of cores has exceeded`.

Все доступные в зоне платформы (`standard-v2`, `standard-v3`, `highfreq-v3`)
требуют минимум **2 ядра** на ВМ — обойти квоту, сделав 1-ядерные ноды,
нельзя. `standard-v1` в зоне `d` недоступен.

### 2. Зоны `ru-central1-a` и `ru-central1-b` недоступны

- `ru-central1-a` — `Resource allocation is restricted`;
- `ru-central1-b` — `Zone is not available`.

Поэтому разнести ноды по трём зонам, как требует ТЗ, сейчас нельзя.

### 3. Жёсткие квоты на диски

- SSD в `ru-central1-d` — всего **10 ГБ** (заняты диском master);
- HDD в `ru-central1-d` — всего **20 ГБ** (заняты диском worker).

С текущими квотами третьей ноде не хватит места под диск, даже если
увеличат только vCPU.

### 4. Диски маленькие и медленные

- master: 10 ГБ SSD — впритык для control plane, etcd и образов;
- worker: 20 ГБ HDD — медленнее SSD, Kubespray и мониторинг будут
  устанавливаться дольше.

### 5. Нет домена

Домен появится ориентировочно 24.10.2026. Пока DNS выключен, ingress
работает с заглушками `app.example.com` и `grafana.example.com`,
HTTPS и cert-manager не настроены.

### 6. Заглушки в конфигурации

- пароль Grafana (`<пароль>`);
- email для Let's Encrypt (`admin@example.com`);
- `APP_HOST` / `APP_TLS_ENABLED` в GitHub Variables.

### 7. Секреты GitHub Actions не созданы

Нужны `YC_SA_KEY_JSON`, `YC_STORAGE_ACCESS_KEY`, `YC_STORAGE_SECRET_KEY`,
`KUBECONFIG_B64` и переменные `APP_HOST`, `APP_TLS_ENABLED`.

## Что осталось сделать

### Шаг 1. Запросить квоты в консоли Yandex Cloud

Запросить увеличение (подробности — `docs/quota.md`):

- `compute.vcpu.count` — до **8**;
- `compute.disks.ssd.size` — до **60–100 ГБ**;
- `compute.disks.hdd.size` — до **60–100 ГБ**;
- `compute.instances.count` — до 6;
- `vpc.externalAddresses.count` — до 8.

Также проверить, что пробный период активен и платёжный метод привязан.

### Шаг 2. Вернуть полноценные 3 ноды

После увеличения квот в `infra/terraform/variables.tf`:

- `workers.count = 2`;
- диски: master 20 ГБ SSD, worker 20 ГБ HDD (или SSD, если дадут квоту);
- при необходимости разнести worker по зонам.

```bash
cd infra/terraform
export AWS_PROFILE=diploma
terraform apply
cat ../ansible/inventory.ini
```

### Шаг 3. Установить Kubernetes

```bash
cd infra/ansible
make deps
make ping
make cluster
make kubeconfig
kubectl get nodes -o wide
kubectl get pods -A
```

### Шаг 4. Ingress и мониторинг

```bash
cd k8s
# команды из k8s/README.md:
# ingress-nginx -> kube-prometheus-stack -> namespace app -> RBAC -> секрет Grafana
```

Проверить Grafana через `http://<NLB_IP>` (пока без домена — Host-заголовок).

### Шаг 5. CI/CD

1. Создать GitHub Secrets и Variables (список выше).
2. Прогнать Terraform pipeline: PR → комментарий с планом → merge в main.
3. Собрать образ коммитом в main.
4. Поставить тег `v1.0.0`, проверить деплой и `kubectl rollout status`.

### Шаг 6. Домен и HTTPS

1. Делегировать домен на NS Яндекса.
2. В `infra/terraform/terraform.tfvars`: `manage_dns = true`,
   `domain_name = "<домен>"`.
3. `terraform apply` — появятся A-записи `app` и `grafana`.
4. Установить cert-manager, заменить email в ClusterIssuer, включить TLS
   в values приложения и Grafana.

### Шаг 7. Сдача

- [ ] скриншоты `terraform apply`, `kubectl get nodes`, `kubectl get pods -A`;
- [ ] дашборды Grafana и Alertmanager;
- [ ] PR с планом Terraform и успешные запуски GitHub Actions;
- [ ] приложение и Grafana в браузере;
- [ ] при необходимости разделить монорепозиторий на 3 репозитория
      (`docs/split-repos.md`).

## Незакоммиченные изменения

- `infra/terraform/variables.tf` — текущая конфигурация под квоту 4 vCPU
  (1 worker). Перед возвратом к 3 нодам изменить `workers.count` на 2.
