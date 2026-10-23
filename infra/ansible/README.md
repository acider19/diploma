# Ansible / Kubespray

`inventory.ini` генерируется Terraform-ом (`infra/terraform`) и в git не попадает.

## Установка кластера

```bash
cd infra/ansible
make deps          # клонирует Kubespray v2.27.0 и ставит зависимости в .venv
make ping          # ansible all -m ping
make cluster       # ansible-playbook kubespray/cluster.yml -b
make kubeconfig    # admin.conf -> ~/.kube/config с публичным IP мастера
kubectl get pods --all-namespaces
```

## Параметры

- Kubernetes `v1.31.4`, Calico, kube-proxy в режиме IPVS;
- control plane и etcd на одной ноде (экономный вариант для диплома);
- worker-ноды прерываемые, поэтому приложение и ingress запускаются минимум в
  двух репликах.

Версия Kubespray зафиксирована в `Makefile` (`KUBESPRAY_VERSION`), чтобы
повторная установка с нуля давала идентичный результат.
