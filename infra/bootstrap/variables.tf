variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID where the diploma resources live"
  type        = string
}

variable "zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "terraform_sa_id" {
  description = "ID of the service account Terraform runs as"
  type        = string
}

variable "bucket_name" {
  description = "Object Storage bucket for the remote Terraform state"
  type        = string
}

variable "registry_name" {
  description = "Container Registry name for the application images"
  type        = string
  default     = "diploma-app"
}
