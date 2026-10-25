variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  description = "Зона по умолчанию для control-plane и сети"
  type        = string
  default     = "ru-central1-d"
}

variable "worker_zones" {
  description = "Зоны размещения worker-нод (в текущем облаке доступна только d)"
  type        = list(string)
  default     = ["ru-central1-d"]
}

# Worker'ам нет публичного IP — SSH через master
variable "workers_public_ip" {
  description = "Выдавать worker-нодам публичный IP (NAT)"
  type        = bool
  default     = false
}

variable "network_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnets" {
  description = "Подсети кластера, по одной на зону доступности"
  type = map(object({
    zone = string
    cidr = string
  }))
  default = {
    a = { zone = "ru-central1-a", cidr = "10.10.1.0/24" }
    b = { zone = "ru-central1-b", cidr = "10.10.2.0/24" }
    d = { zone = "ru-central1-d", cidr = "10.10.3.0/24" }
  }
}

variable "ssh_public_key_path" {
  description = "Публичный SSH-ключ, который добавляется на все ноды"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR, которым разрешён SSH на ноды"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Образ Ubuntu зафиксирован, чтобы не пересоздавать ВМ после обновления образа
variable "ubuntu_image_id" {
  description = "ID образа Ubuntu 22.04 для загрузочных дисков нод"
  type        = string
  default     = "fd8em71f8oo1hdpali1k"
}

variable "master" {
  type = object({
    name          = string
    cores         = number
    memory_gb     = number
    core_fraction = number
    disk_gb       = number
    disk_type     = string
  })
  default = {
    name          = "diploma-master"
    cores         = 2
    memory_gb     = 4
    core_fraction = 50
    disk_gb       = 10
    disk_type     = "network-ssd"
  }
}

variable "workers" {
  type = object({
    count         = number
    cores         = number
    memory_gb     = number
    core_fraction = number
    disk_gb       = number
    disk_type     = string
  })
  default = {
    count         = 2
    cores         = 2
    memory_gb     = 4
    core_fraction = 50
    disk_gb       = 20
    disk_type     = "network-hdd"
  }
}

variable "manage_dns" {
  description = "Создавать DNS-зону и записи в Yandex DNS (домен должен быть делегирован на NS Яндекса)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Базовый домен, например example.com. Используется для app.<домен> и grafana.<домен>"
  type        = string
  default     = ""
}

variable "app_hostname" {
  description = "Явное имя хоста для тестового приложения (необязательно)"
  type        = string
  default     = ""
}

variable "grafana_hostname" {
  description = "Явное имя хоста для Grafana (необязательно)"
  type        = string
  default     = ""
}
