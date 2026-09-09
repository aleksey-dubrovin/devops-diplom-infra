# Провайдер Yandex Cloud для управления ресурсами
provider "yandex" {
  clouid_id           = var.cloud_id              # Идентификатор облака
  folder_id           = var.folder_id             # Идентификатор папки
  service_account_key = var.service_account_key   # JSON-ключ сервисного аккаунта
}

# Вывод для проверки корректной инициализации Terraform
output "test_output" {
  value = "Terraform initialized successfully with S3 backend!"
}
