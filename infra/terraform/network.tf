resource "yandex_vpc_network" "this" {
  name        = "diploma-net"
  description = "Сеть для дипломного Kubernetes-кластера"
}

resource "yandex_vpc_subnet" "this" {
  for_each = var.subnets

  name           = "diploma-${each.key}"
  description    = "Подсеть Kubernetes ${each.key}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = null
}

resource "yandex_vpc_security_group" "k8s" {
  name        = "diploma-k8s"
  description = "Внутренний трафик кластера, SSH, Kubernetes API и ingress"
  network_id  = yandex_vpc_network.this.id

  # Всё внутри кластера: etcd, kubelet, Calico, NodePort и т.д.
  ingress {
    description    = "Внутренний трафик кластера"
    protocol       = "ANY"
    v4_cidr_blocks = [var.network_cidr]
  }

  # Административный SSH только из доверенных сетей.
  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.ssh_allowed_cidrs
  }

  # Kubernetes API для раннеров GitHub Actions (у них динамические IP).
  ingress {
    description    = "Kubernetes API"
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort, которые ingress-nginx публикует за сетевым балансировщиком.
  ingress {
    description    = "NodePort ingress"
    protocol       = "TCP"
    from_port      = 30080
    to_port        = 30443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "ICMP"
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
