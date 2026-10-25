# Чек-лист защиты

## Соответствие требованиям ТЗ

| № | Требование ТЗ | Где смотреть | Статус |
|---|---|---|---|
| 1 | Репозиторий Terraform, создание с нуля | `infra/bootstrap`, `infra/terraform` | готово |
| 2 | Backend для state в Object Storage | `infra/terraform/backend.tf`, бакет `diploma-tfstate-b1g68t7p4rjq035vq0o9` | готово |
| 3 | VPC с подсетями в разных зонах | `infra/terraform/network.tf`, подсети a/b/d | готово |
| 4 | Terraform pipeline с планом и применением | `.github/workflows/terraform.yml`, runs «Terraform» в GitHub Actions | готово |
| 5 | Ansible-конфигурация кластера | `infra/ansible` (Kubespray 2.27.0, K8s 1.31.4) | готово |
| 6 | Минимум 3 ВМ в кластере | 1 master + 2 worker, `kubectl get nodes -o wide` | готово |
| 7 | Dockerfile и ссылка на образ | `app/Dockerfile`, `cr.yandex/crptd2h3nubo1b64a071/diploma-app` | готово |
| 8 | Репозиторий конфигурации Kubernetes | `k8s/`, `app/helm` | готово |
| 9 | Мониторинг: Prometheus, Grafana, Alertmanager, node-exporter | `kubectl get pods -n monitoring`, цели Prometheus 29/29 up | готово |
| 10 | HTTP-доступ к Grafana и приложению | `http://grafana.muravskij.ru` → 308 на HTTPS, `https://...` → 200/302 | готово |
| 11 | Дашборды состояния кластера | Grafana → Dashboards → Kubernetes / Compute Resources | готово |
| 12 | Сборка образа при коммите | `.github/workflows/app.yml`, job «Сборка и публикация образа» | готово |
| 13 | Деплой по тегу `v*` | тег `v1.0.0`, образ `diploma-app:v1.0.0` в кластере | готово |
| 14 | Все репозитории на одном ресурсе | GitHub `acider19` | готово |

## Доступы и адреса

| Что | Значение |
|---|---|
| Приложение | <https://app.muravskij.ru> |
| Grafana | <https://grafana.muravskij.ru> |
| Grafana admin | `admin` / `NetologyDiploma2026!` (секрет `grafana-admin` в namespace `monitoring`) |
| IP балансировщика | 51.250.3.42 |
| Master (SSH) | `ubuntu@<IP из output terraform master_ip>` |
| Container Registry | `cr.yandex/crptd2h3nubo1b64a071/diploma-app` |
| Домен | `muravskij.ru` (Yandex Cloud DNS) |

## Что показать на защите

1. `cd infra/terraform && terraform plan` — «No changes»: инфраструктура описана
   кодом и не расходится с реальностью.
2. GitHub Actions → workflow «Terraform» → последний запуск: plan и apply.
3. `kubectl get nodes -o wide` — 3 ноды Ready, worker-ноды без публичных IP.
4. `kubectl get pods -A` — все поды Running.
5. `https://app.muravskij.ru` — приложение, сертификат Let's Encrypt.
6. `https://grafana.muravskij.ru` — дашборды Kubernetes / Nodes / Pods.
7. `http://app.muravskij.ru` — 308 на HTTPS (доступ на 80 порту есть).
8. Коммит в приложение → workflow «App CI/CD» собирает и пушит образ.
9. Тег `v1.0.0` → job «Деплой по тегу» → `kubectl rollout status -n app deploy/diploma-app`.
10. Откат: `helm history diploma-app -n app` и `helm rollback diploma-app <REV>`.

## Полезные команды для демонстрации

```bash
# состояние кластера
kubectl get nodes -o wide
kubectl get pods -A -o wide

# сертификаты Let's Encrypt
kubectl get certificate -A

# цели Prometheus (все должны быть up)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.health) \(.labels.job)"' | sort | uniq -c

# проверка HTTPS снаружи
curl -sI https://app.muravskij.ru | head -1
curl -sI https://grafana.muravskij.ru | head -1
```

## Скриншоты, которые нужно снять

- [ ] терминал: `terraform apply` (создание ресурсов);
- [ ] GitHub Actions: успешный запуск «Terraform» (plan + apply);
- [ ] GitHub Actions: успешный запуск «App CI/CD» по тегу `v1.0.0`;
- [ ] `kubectl get nodes -o wide` и `kubectl get pods -A`;
- [ ] `kubectl get certificate -A` — сертификаты `Ready=True`;
- [ ] Grafana: дашборды Cluster / Nodes / Pods;
- [ ] Alertmanager (доступ через `kubectl port-forward`);
- [ ] браузер: `https://app.muravskij.ru` и `https://grafana.muravskij.ru` с замком в адресной строке;
- [ ] Pull Request с планом Terraform (если демонстрируется PR-сценарий).
