variable "yandex_token" {
  description = "Токен для доступа к Yandex Cloud"
  type        = string
  sensitive   = true
}  

variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "default_zone" {
  description = "Зона по умолчанию для ресурсов Yandex Cloud"
  type        = string
  default     = "ru-central1-d"
}

variable "sa_name" {
  description = "Имя существующего сервисного аккаунта"
  type        = string
}

variable "bucket_name" {
  description = "Уникальное имя бакета для хранения состояния Terraform"
  type        = string
}

