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
  value = {
    "ru-central1-a" = yandex_compute_instance.worker_a.network_interface[0].ip_address
    "ru-central1-b" = yandex_compute_instance.worker_b.network_interface[0].ip_address
  }
}