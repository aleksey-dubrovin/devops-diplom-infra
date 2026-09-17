# =============================================================================
# VPC и подсети
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
  description = "ID приватных подсетей (по зонам)"
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

# =============================================================================
# Security Groups
# =============================================================================

output "security_group_ids" {
  description = "Карта ID security групп (ключ — имя группы)"
  value       = module.security_group.security_group_ids
}

# =============================================================================
# IAM / сервисные аккаунты
# =============================================================================

output "k8s_service_account_id" {
  description = "ID сервисного аккаунта для Managed K8s"
  value       = module.iam_k8s.service_account_id
}

# =============================================================================
# Managed Kubernetes
# =============================================================================

output "k8s_cluster_id" {
  description = "ID кластера Kubernetes"
  value       = module.k8s_cluster.cluster_id
}

output "k8s_cluster_endpoint" {
  description = "Внутренний endpoint кластера K8s"
  value       = module.k8s_cluster.cluster_endpoint
}

output "k8s_cluster_external_endpoint" {
  description = "Внешний endpoint кластера K8s (если public_access = true)"
  value       = module.k8s_cluster.cluster_external_endpoint
}

output "k8s_cluster_ca_certificate" {
  description = "CA-сертификат кластера K8s (для kubeconfig)"
  value       = module.k8s_cluster.cluster_ca_certificate
  sensitive   = true
}

# =============================================================================
# Compute: bastion и worker-узлы
# =============================================================================

output "bastion_public_ip" {
  description = "Публичный IP bastion-хоста"
  value       = module.compute.bastion_public_ip
}

output "bastion_internal_ip" {
  description = "Внутренний IP bastion-хоста (для маршрутизации)"
  value       = module.compute.bastion_internal_ip
}

output "bastion_ssh_command" {
  description = "Готовая команда для SSH-подключения к bastion"
  value       = module.compute.bastion_ssh_command
}

output "worker_internal_ips" {
  description = "Карта внутренних IP worker-узлов (ключ — зона)"
  value       = module.compute.worker_internal_ips
}

output "worker_internal_ips_list" {
  description = "Список внутренних IP worker-узлов (для манифеста NodeGroup)"
  value       = values(module.compute.worker_internal_ips)
}

output "worker_ssh_commands_via_bastion" {
  description = "Готовые команды для SSH-подключения к worker-узлам через bastion"
  value = {
    for zone, ip in module.compute.worker_internal_ips :
    zone => "ssh -i ~/.ssh/key -J ubuntu@${module.compute.bastion_public_ip} ubuntu@${ip}"
  }
}

output "external_nodegroup_manifest" {
  description = "Готовый YAML-манифест NodeGroup с подставленными IP worker-узлов"
  value = templatefile("${path.module}/templates/nodegroup.yaml.tpl", {
    nodegroup_name  = var.external_nodegroup_name
    namespace       = "yandex-system"
    ssh_secret_name = "external-node-ssh-key"
    worker_ips      = module.compute.worker_internal_ips_list
  })
}

output "external_nodegroup_ips" {
  description = "Список IP-адресов, попавших в манифест NodeGroup"
  value       = module.compute.worker_internal_ips_list
}

output "nlb_ingress_external_ip" {
  description = "Внешний IP NLB для ingress"
  value       = yandex_lb_network_load_balancer.k8s_ingress.listener.*.external_address_spec[0].address
}