variable "sa_name" {
  description = "Имя сервисного аккаунта"
  type        = string
}

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
}

variable "roles" {
  description = "Список ролей для сервисного аккаунта (в формате 'storage.editor', 'editor' и т.д.)"
  type        = list(string)
  default     = ["editor", "storage.editor"]
}

variable "create_sa" {
  description = "Создавать новый аккаунт или использовать существующий"
  type        = bool
  default     = false
}