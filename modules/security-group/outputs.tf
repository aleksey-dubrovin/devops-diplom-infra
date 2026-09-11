# =============================================================================
# Выходные данные модуля security-group
# =============================================================================

output "security_group_ids" {
  description = "Карта ID созданных security групп (ключ — имя группы)"
  value       = { for k, v in yandex_vpc_security_group.this : k => v.id }
}

output "security_group_names" {
  description = "Карта имён созданных security групп"
  value       = { for k, v in yandex_vpc_security_group.this : k => v.name }
}