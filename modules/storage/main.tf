# Создание статического ключа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = var.service_account_id
  description        = "Статический ключ для доступа к бакету ${var.bucket_name}"
}

# Создание S3-бакета
resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_key.secret_key
  force_destroy = var.force_destroy

  versioning {
    enabled = var.enable_versioning
  }

}