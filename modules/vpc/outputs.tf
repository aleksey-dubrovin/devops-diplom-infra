# =============================================================================
# Выходные данные модуля VPC
# =============================================================================

output "vpc_id" {
  description = "ID созданной VPC"
  value       = yandex_vpc_network.main.id
}

output "public_subnet_ids" {
  description = "ID публичных подсетей (по зонам)"
  value       = { for k, v in yandex_vpc_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "ID приватных подсетей (по зонам)"
  value       = { for k, v in yandex_vpc_subnet.private : k => v.id }
}

output "mgmt_subnet_ids" {
  description = "ID управляющих подсетей (по зонам)"
  value       = { for k, v in yandex_vpc_subnet.mgmt : k => v.id }
}

output "nat_gateway_id" {
  description = "ID NAT-шлюза (если создан)"
  value       = var.enable_nat ? yandex_vpc_gateway.nat[0].id : null
}

output "route_table_id" {
  description = "ID таблицы маршрутизации (если создана)"
  value       = var.enable_nat ? yandex_vpc_route_table.nat[0].id : null
}

output "s3_private_endpoint_id" {
  description = "ID приватного эндпоинта Object Storage"
  value       = var.s3_private_endpoint.enable ? yandex_vpc_private_endpoint.s3[0].id : null
}