# Git-репозиторий с конфигурацией Kubernetes-кластера

- `helm/ingress-nginx` — values для ingress-контроллера, публикующего NodePort 30080/30443;
- `helm/kube-prometheus-stack` — Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics;
- `manifests/` — namespace, RBAC для CI, пример секрета Grafana, ClusterIssuer Let's Encrypt.

Полная инструкция по установке — в `README.md` внутри этой директории.
