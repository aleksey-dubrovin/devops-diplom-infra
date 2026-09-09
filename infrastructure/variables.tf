# Access Key для доступа к S3-бакету (статический ключ)
variable "access_key" {
  description = "Access Key для доступа к S3-бакету (статический ключ)"
  type        = string
  sensitive   = true 
}

# Secret Key для доступа к S3-бакету (статический ключ)
variable "secret_key" {
  description = "Secret Key для доступа к S3-бакету (статический ключ)"
  type        = string
  sensitive   = true
}

# Имя S3-бакета для хранения состояния Terraform
variable "bucket_name" {
  description = "Имя S3-бакета для хранения состояния Terraform"
  type        = string
}

# JSON-ключ сервисного аккаунта для аутентификации провайдера Yandex Cloud
variable "service_account_key" {
  description = "JSON-ключ сервисного аккаунта для аутентификации провайдера Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
    description = "ID облака в Yandex Сloud"
    type        = string
}

# ID папки в Yandex Cloud, где будут создаваться ресурсы
variable "folder_id" {
  description = "ID папки в Yandex Cloud"
  type        = string
}

variable "default_zone" {
    description = "Зона доступности Yandex Cloud"
    type = string
    default     ="ru-central1-d"
}