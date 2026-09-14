output "bastion_ip" {
  description = "Публичный IP bastion-хоста"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "bastion_internal_ip" {
  description = "Внутренний IP bastion-хоста"
  value       = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "worker_internal_ips" {
  description = "Карта внутренних IP worker-узлов (ключ — зона)"
  value       = { for k, v in yandex_compute_instance.worker : k => v.network_interface[0].ip_address }
}