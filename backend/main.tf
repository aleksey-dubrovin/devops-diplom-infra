terraform {
  required_version = ">= 1.3.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "> 0.9"
    }
  }
}  
provider "yandex" {
  token     = var.yandex_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}

module "iam" {
  source = "../modules/iam"
  sa_name     = var.sa_name
  folder_id   = var.folder_id
  roles       = ["editor", "storage.editor", "container-registry.admin", "dns.editor"]
  create_sa   = false   # false – использовать существующий аккаунт
}

# Вызов модуля storage для создания бакета и ключей
module "storage" {
  source = "../modules/storage"
  bucket_name         = "${var.bucket_name}-${var.folder_id}"  # Уникальное имя бакета с добавлением ID папки
  service_account_id  = module.iam.service_account_id
  enable_versioning   = true
  force_destroy       = true
}

