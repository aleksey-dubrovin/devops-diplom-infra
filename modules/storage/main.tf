# =============================================================================
# Модуль Storage
# Назначение: создание S3-бакета и статического ключа доступа
# =============================================================================

# -----------------------------------------------------------------------------
# Статический ключ доступа для сервисного аккаунта
# -----------------------------------------------------------------------------
# Создание статического ключа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = var.service_account_id
  description        = "Статический ключ для доступа к бакету ${var.bucket_name}"
}

# -----------------------------------------------------------------------------
# S3-бакет для хранения состояния Terraform
# -----------------------------------------------------------------------------
resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.bucket_name
  # Ключи доступа для S3-совместимого API
  access_key = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_key.secret_key
  force_destroy = var.force_destroy

  # Версионирование объектов
  versioning {
    enabled = var.enable_versioning
  }
}
