# =============================================================================
# Выходные данные инфраструктуры
# =============================================================================

output "vpc_id" {
  description = "ID созданной VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "ID публичных подсетей (по зонам)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "ID приватных подсетей (для внешних узлов, по зонам)"
  value       = module.vpc.private_subnet_ids
}

output "mgmt_subnet_ids" {
  description = "ID управляющих подсетей (для Managed K8s, по зонам)"
  value       = module.vpc.mgmt_subnet_ids
}

output "nat_gateway_id" {
  description = "ID NAT-шлюза"
  value       = module.vpc.nat_gateway_id
}

output "s3_private_endpoint_id" {
  description = "ID приватного эндпоинта Object Storage"
  value       = module.vpc.s3_private_endpoint_id
}