variable "bucket_name" {
  description = "Уникальное имя бакета"
  type        = string
  sensitive   = true
}

variable "service_account_id" {
  description = "ID сервисного аккаунта, от имени которого будут созданы ключи"
  type        = string
}

variable "enable_versioning" {
  description = "Включить версионирование в бакете"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Разрешить удаление бакета с объектами"
  type        = bool
  default     = true
}