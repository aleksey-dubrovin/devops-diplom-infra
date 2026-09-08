# =============================================================================
# Выходные параметры модуля Storage
# =============================================================================

output "bucket_name" {
  description = "Имя бакета"
  value       = yandex_storage_bucket.tfstate.bucket
  sensitive   = true
}

output "access_key" {
  description = "Access Key"
  value       = yandex_iam_service_account_static_access_key.sa_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret Key"
  value       = yandex_iam_service_account_static_access_key.sa_key.secret_key
  sensitive   = true
}
