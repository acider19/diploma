resource "yandex_lb_target_group" "ingress" {
  name      = "diploma-ingress"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.worker
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

# У self-hosted Kubernetes нет cloud controller manager, поэтому ingress-nginx
# публикуется через NodePort, а внешний NLB проксирует на него 80/443.
resource "yandex_lb_network_load_balancer" "ingress" {
  name = "diploma-ingress"
  type = "external"

  listener {
    name        = "http"
    port        = 80
    target_port = 30080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name        = "https"
    port        = 443
    target_port = 30443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.ingress.id

    healthcheck {
      name                = "ingress-http"
      interval            = 5
      timeout             = 3
      healthy_threshold   = 2
      unhealthy_threshold = 3

      tcp_options {
        port = 30080
      }
    }
  }
}
