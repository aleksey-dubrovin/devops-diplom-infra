# =============================================================================
# Настройка провайдера Yandex Cloud
# =============================================================================
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  folder_id                = var.folder_id
  cloud_id                 = var.cloud_id
  zone                     = var.default_zone
}

# =============================================================================
# Модуль VPC — создание сети и подсетей
# =============================================================================
module "vpc" {
  source    = "../modules/vpc"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  vpc_name  = var.vpc_name

  # CIDR-блоки для разных типов подсетей
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  mgmt_subnet_cidrs    = var.mgmt_subnet_cidrs

  # NAT-шлюз для приватных подсетей
  enable_nat       = true
  nat_gateway_name = var.nat_gateway_name

  # Приватный эндпоинт для Object Storage (S3)
  s3_private_endpoint = {
    enable = true
    zone   = "ru-central1-d"
    name   = "s3-private-endpoint"
  }
}