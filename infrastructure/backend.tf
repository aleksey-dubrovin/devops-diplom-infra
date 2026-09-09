# Настройка бэкенда для хранения состояния Terraform в Yandex Object Storage
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"  # Yandex Cloud Object Storage endpoint
    bucket     = var.bucket_name            # Имя бакета для хранения состояния
    key        = "infra.tfstate"            # Путь к файлу состояния внутри бакета
    region     = "ru-central1"              # Регион Yandex Cloud
    access_key = var.access_key             # Ключ доступа из переменных
    secret_key = var.secret_key             # Секретный ключ из переменных
  }
}
