output "bucket_name" {
  description = "Bucket that stores the main infrastructure state"
  value       = yandex_storage_bucket.tfstate.bucket
}

output "registry_id" {
  value = yandex_container_registry.app.id
}

output "registry_url" {
  value = "cr.yandex/${yandex_container_registry.app.id}"
}

output "terraform_service_account_id" {
  value = data.yandex_iam_service_account.terraform.id
}
