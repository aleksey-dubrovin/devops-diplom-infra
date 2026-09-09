# Секретные переменные (передаются через переменные окружения или секреты GitHub)
variable "access_key" {
  description = "Ключ доступа S3 для бэкенда состояния Terraform"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Секретный ключ S3 для бэкенда состояния Terraform"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Имя бакета S3 для хранения состояния Terraform"
  type        = string
}

variable "service_account_key" {
  description = "JSON-ключ для сервисного аккаунта Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Идентификатор облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "Идентификатор папки Yandex Cloud"
  type        = string
}
