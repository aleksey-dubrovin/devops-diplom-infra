# Блок terraform описывает настройки самого Terraform, включая требуемые провайдеры и бэкенд
terraform {
  # Список требуемых провайдеров с указанием источника и версии
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      # Версия не указана, будет использоваться последняя совместимая
    }
  }

  # Конфигурация бэкенда для хранения состояния (state-файла) в S3-совместимом хранилище Yandex Object Storage
  backend "s3" {
    # Явное указание эндпоинта для S3-совместимого API Yandex Cloud
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "devops-diplom-tf-b1glfq89j9n7quk0cnf0"
    # Регион расположения бакета
    region = "ru-central1"

    # Путь и имя файла состояния внутри бакета
    key = "infra.tfstate"

    # Параметры для совместимости с S3-совместимыми хранилищами
    # Отключает проверку региона (иначе Terraform будет жаловаться на ru-central1)
    skip_region_validation = true

    # Отключает проверку учётных данных через AWS API (ускоряет инициализацию)
    skip_credentials_validation = true

    # Отключает запрос ID аккаунта (необходимо для Terraform 1.6.1 и старше)
    skip_requesting_account_id = true

    # Отключает проверку контрольной суммы для объектов S3 (необходимо для Terraform 1.6.3 и старше)
    skip_s3_checksum = true

    # Заставляет Terraform использовать URL вида https://storage.yandexcloud.net/<bucket>/<key>
    force_path_style = true

  }
}

provider "yandex" {
  service_account_key = var.service_account_key
  folder_id = var.folder_id
  cloud-id = var.cloud_id
  zone      = var.default_zone
}