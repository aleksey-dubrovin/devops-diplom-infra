# =============================================================================
# Идентификаторы
# =============================================================================

variable "folder_id" {
  description = "ID папки Yandex Cloud"
  type        = string
}

variable "network_id" {
  description = "ID VPC, к которой будут привязаны security groups"
  type        = string
}

# =============================================================================
# Карта security групп с правилами
# =============================================================================
# Формат:
# security_groups = {
#   "sg-name" = {
#     description = "Описание группы"
#     ingress = [
#       {
#         protocol       = "TCP"
#         description    = "Описание правила"
#         port           = 22          # или from_port/to_port
#         v4_cidr_blocks = ["0.0.0.0/0"]
#       }
#     ]
#     egress = [
#       {
#         protocol       = "ANY"
#         description    = "Разрешить весь исходящий трафик"
#         from_port      = 0
#         to_port        = 65535
#         v4_cidr_blocks = ["0.0.0.0/0"]
#       }
#     ]
#   }
# }
# =============================================================================

variable "security_groups" {
  description = "Карта security групп с правилами ingress и egress"
  type = map(object({
    description = optional(string, "")
    ingress = optional(list(object({
      protocol          = string
      description       = optional(string, "")
      port              = optional(number)
      from_port         = optional(number)
      to_port           = optional(number)
      v4_cidr_blocks    = optional(list(string), [])
      security_group_id = optional(string)
      predefined_target = optional(string)
    })), [])
    egress = optional(list(object({
      protocol          = string
      description       = optional(string, "")
      port              = optional(number)
      from_port         = optional(number)
      to_port           = optional(number)
      v4_cidr_blocks    = optional(list(string), [])
      security_group_id = optional(string)
      predefined_target = optional(string)
    })), [])
  }))
  default = {}
}