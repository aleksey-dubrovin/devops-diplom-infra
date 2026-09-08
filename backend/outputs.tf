# =============================================================================
# Выходные параметры (backend)
# =============================================================================

output "bucket_name" {
  description = "Имя созданного бакета"
  value       = module.storage.bucket_name
  sensitive   = true
}

output "access_key" {
  description = "Access Key для доступа к бакету"
  value       = module.storage.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret Key для доступа к бакету"
  value       = module.storage.secret_key
  sensitive   = true
}

output "service_account_id" {
  description = "ID сервисного аккаунта"
  value       = module.iam.service_account_id
}
