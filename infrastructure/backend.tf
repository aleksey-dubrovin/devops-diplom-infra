# Настройка бэкенда для хранения состояния Terraform в Yandex Object Storage
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"  # Yandex Cloud Object Storage endpoint
    key        = "infra.tfstate"            # Путь к файлу состояния внутри бакета
    region     = "ru-central1"              # Регион Yandex Cloud
  }
}
