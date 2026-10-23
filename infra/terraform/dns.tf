locals {
  app_hostname     = var.app_hostname != "" ? var.app_hostname : "app.${var.domain_name}"
  grafana_hostname = var.grafana_hostname != "" ? var.grafana_hostname : "grafana.${var.domain_name}"
}

# Чтобы зона была авторитетной, домен должен быть делегирован на NS Яндекса.
# Включайте manage_dns после регистрации домена.
resource "yandex_dns_zone" "this" {
  count = var.manage_dns ? 1 : 0

  name        = "diploma-zone"
  description = "DNS-зона дипломного проекта"
  zone        = "${var.domain_name}."
  public      = true

  labels = {
    project = "diploma"
  }
}

resource "yandex_dns_recordset" "app" {
  count = var.manage_dns ? 1 : 0

  zone_id = yandex_dns_zone.this[0].id
  name    = local.app_hostname
  type    = "A"
  ttl     = 300
  data    = [local.nlb_ip]
}

resource "yandex_dns_recordset" "grafana" {
  count = var.manage_dns ? 1 : 0

  zone_id = yandex_dns_zone.this[0].id
  name    = local.grafana_hostname
  type    = "A"
  ttl     = 300
  data    = [local.nlb_ip]
}
