# =============================================================================
# Идентификаторы
# =============================================================================

variable "cloud_id" {
    description = "ID облака Yandex Cloud"
    type        = string
}

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
}

# =============================================================================
# Настройки VPC
# =============================================================================

variable "vpc_name" {
  description = "Имя VPC"
  type        = string
  default     = "diplom-vpc"
}

variable "public_subnet_cidrs" {
  description = "CIDR-блоки для публичных подсетей (по зонам)"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR-блоки для приватных подсетей (по зонам)"
  type        = map(string)
}

variable "mgmt_subnet_cidrs" {
  description = "CIDR-блоки для управляющих подсетей Managed K8s (по зонам)"
  type        = map(string)
}

# =============================================================================
# NAT-шлюз
# =============================================================================

variable "enable_nat" {
  description = "Создать NAT-шлюз для приватных подсетей"
  type        = bool
  default     = true
}

variable "nat_gateway_name" {
  description = "Имя NAT-шлюза"
  type        = string
  default     = "diplom-nat-gw"
}

# =============================================================================
# Приватный эндпоинт для S3
# =============================================================================

variable "s3_private_endpoint" {
  description = "Настройки приватного эндпоинта для Object Storage"
  type = object({
    enable = bool
    zone   = optional(string, "ru-central1-d")
    name   = optional(string, "s3-private-endpoint")
  })
  default = {
    enable = false
    zone   = "ru-central1-d"
    name   = "s3-private-endpoint"
  }
}