# Блок конфигурации Terraform
terraform {
  # Требуемая версия Terraform
  required_version = ">= 1.3.0"

  # Обязательные провайдеры
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "> 0.9"
    }
  }
}
