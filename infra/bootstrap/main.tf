terraform {
  required_version = ">= 1.9"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120, < 1.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# Сервисный аккаунт, под которым работает Terraform, уже существует: выдавать
# роли на каталог может только владелец облака, а текущему ключу менять
# access bindings запрещено. Набор ролей и порядок замены на выделенный SA
# описаны в ../../docs/iam.md.
data "yandex_iam_service_account" "terraform" {
  service_account_id = var.terraform_sa_id
}

# Удалённый backend для state основной инфраструктуры (см. ../terraform/backend.tf).
resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  max_size = 1073741824 # 1 ГиБ, укладываемся в бесплатный лимит

  versioning {
    enabled = true
  }

  anonymous_access_flags {
    read = false
    list = false
  }
}

# Здесь хранятся образы тестового приложения.
resource "yandex_container_registry" "app" {
  name      = var.registry_name
  folder_id = var.folder_id

  labels = {
    project = "diploma"
    managed = "terraform"
  }
}
