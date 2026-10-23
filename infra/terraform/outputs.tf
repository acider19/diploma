locals {
  nlb_ip = one([
    for l in yandex_lb_network_load_balancer.ingress.listener :
    one(l.external_address_spec).address
    if l.name == "http"
  ])

  inventory = templatefile("${path.module}/inventory.tmpl", {
    master_public  = yandex_compute_instance.master.network_interface[0].nat_ip_address
    master_private = yandex_compute_instance.master.network_interface[0].ip_address
    workers = [
      for i, w in yandex_compute_instance.worker : {
        name    = w.name
        public  = w.network_interface[0].nat_ip_address
        private = w.network_interface[0].ip_address
      }
    ]
    ssh_key_path = replace(pathexpand(var.ssh_public_key_path), ".pub", "")
    api_host     = yandex_compute_instance.master.network_interface[0].nat_ip_address
  })
}

resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  content         = local.inventory
  file_permission = "0600"
}

output "master_public_ip" {
  value = yandex_compute_instance.master.network_interface[0].nat_ip_address
}

output "master_private_ip" {
  value = yandex_compute_instance.master.network_interface[0].ip_address
}

output "worker_public_ips" {
  value = [for w in yandex_compute_instance.worker : w.network_interface[0].nat_ip_address]
}

output "worker_private_ips" {
  value = [for w in yandex_compute_instance.worker : w.network_interface[0].ip_address]
}

output "nlb_ip" {
  value = local.nlb_ip
}

output "app_hostname" {
  value = local.app_hostname
}

output "grafana_hostname" {
  value = local.grafana_hostname
}

output "subnet_ids" {
  value = { for k, s in yandex_vpc_subnet.this : k => s.id }
}
