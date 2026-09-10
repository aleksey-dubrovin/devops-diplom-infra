# =============================================================================
# Секретные переменные (передаются через GitHub Secrets)
# =============================================================================

variable "access_key" {
  description = "Access Key для доступа к S3-бакету"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Secret Key для доступа к S3-бакету"
  type        = string
  sensitive   = true
}

variable "service_account_key_file" {
  description = "JSON-ключ сервисного аккаунта для аутентификации провайдера"
  type        = string
  sensitive   = true
}

# =============================================================================
# Идентификаторы Yandex Cloud
# =============================================================================

variable "cloud_id" {
  description = "ID облака в Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID папки в Yandex Cloud"
  type        = string
}

variable "default_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-d"
}

# =============================================================================
# Сетевая инфраструктура
# =============================================================================

variable "vpc_name" {
  description = "Имя VPC"
  type        = string
  default     = "diplom-vpc"
}

variable "public_subnet_cidrs" {
  description = "CIDR-блоки для публичных подсетей (по зонам)"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.1.0/24"
    "ru-central1-b" = "10.0.2.0/24"
    "ru-central1-d" = "10.0.3.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR-блоки для приватных подсетей (по зонам)"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.4.0/24"
    "ru-central1-b" = "10.0.5.0/24"
    "ru-central1-d" = "10.0.6.0/24"
  }
}

variable "mgmt_subnet_cidrs" {
  description = "CIDR-блоки для управляющих подсетей Managed K8s (по зонам)"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.7.0/24"
    "ru-central1-b" = "10.0.8.0/24"
    "ru-central1-d" = "10.0.9.0/24"
  }
}

variable "nat_gateway_name" {
  description = "Имя NAT-шлюза"
  type        = string
  default     = "diplom-nat-gw"
}