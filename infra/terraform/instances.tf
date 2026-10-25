locals {
  ssh_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  # Ключи подсетей совпадают с суффиксом зоны: ru-central1-d -> "d".
  zone_key         = replace(var.zone, "ru-central1-", "")
  worker_zone_keys = [for z in var.worker_zones : replace(z, "ru-central1-", "")]
}

resource "yandex_compute_instance" "master" {
  name                      = var.master.name
  hostname                  = var.master.name
  description               = "Control plane и etcd"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = var.master.cores
    memory        = var.master.memory_gb
    core_fraction = var.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      type     = var.master.disk_type
      size     = var.master.disk_gb
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this[local.zone_key].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = false
  }
}

resource "yandex_compute_instance" "worker" {
  count = var.workers.count

  name                      = "diploma-worker-${count.index + 1}"
  hostname                  = "diploma-worker-${count.index + 1}"
  description               = "Worker-нода Kubernetes (прерываемая)"
  zone                      = var.worker_zones[count.index % length(var.worker_zones)]
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = var.workers.cores
    memory        = var.workers.memory_gb
    core_fraction = var.workers.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      type     = var.workers.disk_type
      size     = var.workers.disk_gb
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this[local.worker_zone_keys[count.index % length(local.worker_zone_keys)]].id
    nat                = var.workers_public_ip
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}
