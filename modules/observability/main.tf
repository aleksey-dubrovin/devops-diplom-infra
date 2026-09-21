# =============================================================================
# Группа логирования для сбора логов из Kubernetes
# =============================================================================
resource "yandex_logging_group" "k8s_logs" {
  name             = var.log_group_name
  folder_id        = var.folder_id
  retention_period = var.log_retention_period
}

# =============================================================================
# Audit Trails для сбора аудитных логов всех ресурсов в папке
# =============================================================================
resource "yandex_audit_trails_trail" "audit_trail" {
  name        = var.audit_trail_name
  folder_id   = var.folder_id
  description = "Audit trail для дипломного проекта"

  service_account_id = var.service_account_id

  logging_destination {
    log_group_id = yandex_logging_group.k8s_logs.id
  }

  filtering_policy {
    management_events_filter {
      resource_scope {
        resource_id   = var.folder_id
        resource_type = "resource-manager.folder"
      }
    }
  }
}