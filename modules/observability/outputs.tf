output "log_group_id" {
  description = "ID созданной группы логирования"
  value       = yandex_logging_group.k8s_logs.id
}

output "audit_trail_id" {
  description = "ID созданного трейла аудита"
  value       = yandex_audit_trails_trail.audit_trail.id
}