terraform {
  required_version = ">= 1.9"

  # Нативный lock через S3 в Yandex Object Storage недоступен, поэтому
  # параллельные запуски сериализуются в CI (concurrency group), а не через DynamoDB.
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "diploma-tfstate-b1g68t7p4rjq035vq0o9"
    key                         = "env/terraform.tfstate"
    region                      = "ru-central1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120, < 1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
