# =============================================================================
# Bastion
# =============================================================================

output "bastion_public_ip" {
  description = "Публичный IP bastion-хоста (для SSH-подключения из интернета)"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "bastion_internal_ip" {
  description = "Внутренний IP bastion-хоста"
  value       = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "bastion_ssh_command" {
  description = "Готовая команда для SSH-подключения к bastion"
  value       = "ssh -i ~/.ssh/aleksey ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address}"
}

# =============================================================================
# Worker-узлы
# =============================================================================

output "worker_internal_ips" {
  description = "Карта внутренних IP worker-узлов (ключ — суффикс имени, как в worker_config.zones)"
  value       = { for k, v in yandex_compute_instance.worker : k => v.network_interface[0].ip_address }
}

output "worker_internal_ips_by_zone" {
  description = "Карта внутренних IP worker-узлов (ключ — зона доступности)"
  value = {
    for k, v in yandex_compute_instance.worker :
    var.worker_config.zones[k] => v.network_interface[0].ip_address
  }
}

output "worker_internal_ips_list" {
  description = "Список внутренних IP worker-узлов (для манифеста NodeGroup)"
  value       = values({ for k, v in yandex_compute_instance.worker : k => v.network_interface[0].ip_address })
}

output "worker_ssh_commands_via_bastion" {
  description = "Карта готовых команд для SSH-подключения к worker-узлам через bastion"
  value = {
    for k, v in yandex_compute_instance.worker :
    var.worker_config.zones[k] => "ssh -i ~/.ssh/aleksey -J ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ubuntu@${v.network_interface[0].ip_address}"
  }
}