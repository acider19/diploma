# Управление установкой Kubernetes через Kubespray.
#
#   make deps      — скачать Kubespray и поставить зависимости в .venv
#   make ping      — проверить SSH-доступ до всех нод
#   make cluster   — установить Kubernetes
#   make kubeconfig— забрать admin.conf в ~/.kube/config
#   make reset     — сбросить кластер (осторожно)

KUBESPRAY_VERSION ?= v2.27.0
KUBESPRAY_DIR     ?= kubespray
VENV              ?= .venv
PYTHON            ?= python3.12
INVENTORY         ?= inventory.ini
MASTER_PUBLIC_IP  ?= $(shell awk '/^diploma-master /{print $$2}' $(INVENTORY) | cut -d= -f2)

.PHONY: deps kubespray venv ping cluster kubeconfig reset clean

deps: venv kubespray

$(KUBESPRAY_DIR):
	git clone --depth 1 --branch $(KUBESPRAY_VERSION) \
		https://github.com/kubernetes-sigs/kubespray.git $(KUBESPRAY_DIR)

kubespray: $(KUBESPRAY_DIR)

$(VENV):
	$(PYTHON) -m venv $(VENV)

venv: $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r $(KUBESPRAY_DIR)/requirements.txt

ping:
	$(VENV)/bin/ansible -i $(INVENTORY) all -m ping

cluster:
	$(VENV)/bin/ansible-playbook -i $(INVENTORY) -b \
		$(KUBESPRAY_DIR)/cluster.yml

kubeconfig:
	mkdir -p $(HOME)/.kube
	sed "s#server: https://[^:]*:#server: https://$(MASTER_PUBLIC_IP):#" \
		$(KUBESPRAY_DIR)/artifacts/admin.conf > $(HOME)/.kube/config
	chmod 600 $(HOME)/.kube/config
	kubectl get nodes -o wide

reset:
	$(VENV)/bin/ansible-playbook -i $(INVENTORY) -b \
		$(KUBESPRAY_DIR)/reset.yml

clean:
	rm -rf $(VENV) $(KUBESPRAY_DIR) artifacts
