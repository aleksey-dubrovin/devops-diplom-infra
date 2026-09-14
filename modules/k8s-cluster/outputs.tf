output "cluster_id" {
  description = "ID созданного кластера"
  value       = yandex_kubernetes_cluster.this.id
}

output "cluster_endpoint" {
  description = "Внутренний endpoint кластера"
  value       = yandex_kubernetes_cluster.this.master[0].internal_v4_endpoint
}

output "cluster_external_endpoint" {
  description = "Внешний endpoint кластера (если public_access = true)"
  value       = yandex_kubernetes_cluster.this.master[0].external_v4_endpoint
}

output "cluster_ca_certificate" {
  description = "CA-сертификат кластера"
  value       = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
  sensitive   = true
}