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
  description = "Срок хранения логов (формат: 1h, 72h, 168h)"
  type        = string
  default     = "72h"
}

variable "audit_trail_name" {
  description = "Имя для трейла аудита"
  type        = string
  default     = "diplom-audit-trail"
}