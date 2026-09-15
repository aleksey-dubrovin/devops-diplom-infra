# =============================================================================
# Идентификаторы
# =============================================================================

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
}

variable "public_subnet_id" {
  description = "ID публичной подсети для bastion-хоста"
  type        = string
}

variable "private_subnet_ids" {
  description = "Карта ID приватных подсетей для worker-узлов (ключ — зона)"
  type        = map(string)
}

variable "security_group_ids" {
  description = "Карта ID групп безопасности (ключ — имя группы)"
  type        = map(string)
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа для доступа к ВМ"
  type        = string
  sensitive   = true
}

variable "image_id" {
  description = "ID конкретного образа Ubuntu (зафиксированный)"
  type        = string
  default     = "fd8nj6iro13qffg31not"
}

# =============================================================================
# Зона для bastion-хоста
# =============================================================================

variable "bastion_zone" {
  description = "Зона доступности для bastion-хоста"
  type        = string
  default     = "ru-central1-d"
}

# =============================================================================
# Параметры bastion-хоста
# =============================================================================

variable "bastion_config" {
  description = "Конфигурация bastion-хоста"
  type = object({
    name          = string
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    preemptible   = bool
    ssh_user      = string
  })
  default = {
    name          = "diplom-bastion"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    core_fraction = 50
    disk_size     = 10
    preemptible   = true
    ssh_user      = "ubuntu"
  }
}

# =============================================================================
# Параметры worker-узлов
# =============================================================================

variable "worker_config" {
  description = "Конфигурация worker-узлов"
  type = object({
    name_prefix   = string
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    preemptible   = bool
    ssh_user      = string
    zones         = map(string)
  })
  default = {
    name_prefix   = "diplom-worker"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 4
    core_fraction = 50
    disk_size     = 20
    preemptible   = true
    ssh_user      = "ubuntu"
    zones = {
      "a" = "ru-central1-a"
      "b" = "ru-central1-b"
    }
  }
}