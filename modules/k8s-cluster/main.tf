# =============================================================================
# Региональный мастер Managed Kubernetes
# =============================================================================
resource "yandex_kubernetes_cluster" "this" {
  name        = var.cluster_name
  description = var.description
  folder_id   = var.folder_id
  network_id  = var.network_id

  # Сетевые диапазоны
  cluster_ipv4_range       = var.cluster_ipv4_range
  service_ipv4_range       = var.service_ipv4_range
  node_ipv4_cidr_mask_size = var.node_ipv4_cidr_mask_size

  # Сервисные аккаунты (используем существующие)
  service_account_id      = var.service_account_id
  node_service_account_id = var.node_service_account_id

  # Канал обновлений
  release_channel = var.release_channel

  # Включаем туннельный режим (Cilium) — обязательно для внешних узлов
  dynamic "network_implementation" {
    for_each = var.enable_cilium_policy ? [1] : []
    content {
      cilium {}
    }
  }

  # Если Cilium выключен, используем Calico
  network_policy_provider = var.enable_cilium_policy ? null : "CALICO"

  master {
    version            = var.cluster_version
    public_ip          = var.public_access
    security_group_ids = var.security_group_ids
    etcd_cluster_size  = var.etcd_cluster_size

    dynamic "master_location" {
      for_each = var.master_locations
      content {
        zone      = master_location.value.zone
        subnet_id = master_location.value.subnet_id
      }
    }

    maintenance_policy {
      auto_upgrade = var.master_auto_upgrade
      dynamic "maintenance_window" {
        for_each = var.master_maintenance_windows
        content {
          day        = maintenance_window.value.day
          start_time = maintenance_window.value.start_time
          duration   = maintenance_window.value.duration
        }
      }
    }

    # Логирование отключено — будет вынесено в отдельный модуль
    master_logging {
      enabled = false
    }

    dynamic "scale_policy" {
      for_each = var.master_scale_policy != null ? [var.master_scale_policy] : []
      content {
        auto_scale {
          min_resource_preset_id = scale_policy.value
        }
      }
    }
  }
}

# =============================================================================
# Роль для туннельного режима (k8s.tunnelClusters.agent)
# =============================================================================
resource "yandex_resourcemanager_folder_iam_member" "tunnel_agent" {
  count = var.enable_cilium_policy ? 1 : 0

  folder_id = var.folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${var.service_account_id}"
}