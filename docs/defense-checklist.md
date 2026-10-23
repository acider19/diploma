# Чек-лист защиты

| № | Требование ТЗ | Где смотреть | Готово |
|---|---|---|---|
| 1 | Репозиторий Terraform, создание с нуля | `infra/`, демонстрация `terraform apply` | после квот |
| 2 | PR с планом Terraform / скриншоты pipeline | `.github/workflows/terraform.yml`, PR-комментарий | после push |
| 3 | Ansible-конфигурация кластера | `infra/ansible` | да |
| 4 | Dockerfile и ссылка на образ | `app/Dockerfile`, `cr.yandex/crptd2h3nubo1b64a071/diploma-app` | после CI |
| 5 | Репозиторий конфигурации Kubernetes | `k8s/` | да |
| 6 | Ссылки на приложение и Grafana + доступы | `http://app.<домен>`, `http://grafana.<домен>` | после домена |
| 7 | Все репозитории на одном ресурсе | GitHub `acider19` | после разделения |

## Что показать на защите

1. `terraform destroy` → `terraform apply` инфраструктуры.
2. `kubectl get nodes`, `kubectl get pods -A`.
3. Приложение и Grafana по HTTP на 80 порту, дашборды с метриками.
4. PR с комментарием плана Terraform.
5. Коммит в приложение → новый образ в registry.
6. Тег `v1.0.0` → деплой новой версии, `kubectl rollout status`.
7. `helm rollback` как демонстрация отката.

## Скриншоты, которые нужно снять

- [ ] вывод `terraform apply` (создание ресурсов);
- [ ] `kubectl get nodes -o wide` и `kubectl get pods -A`;
- [ ] Grafana: Cluster / Nodes / Pods dashboards;
- [ ] Alertmanager с активным тестовым алертом;
- [ ] PR с планом Terraform;
- [ ] успешный запуск GitHub Actions (сборка и деплой);
- [ ] приложение в браузере и `curl -I http://app.<домен>`.
