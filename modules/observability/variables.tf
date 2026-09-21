variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
}

variable "service_account_id" {
  description = "ID сервисного аккаунта, от имени которого будет работать Audit Trails"
  type        = string
}

variable "log_group_name" {
  description = "Имя для группы логирования"
  type        = string
  default     = "diplom-k8s-logs"
}

variable "log_retention_period" {
  description = "Срок хранения логов (например, 1h, 3d, 1w)"
  type        = string
  default     = "3d"
}

variable "audit_trail_name" {
  description = "Имя для трейла аудита"
  type        = string
  default     = "diplom-audit-trail"
}