# =============================================================================
# Настройка провайдера Yandex Cloud
# =============================================================================
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  folder_id                = var.folder_id
  cloud_id                 = var.cloud_id
  zone                     = var.default_zone
}

# =============================================================================
# Модуль VPC — создание сети и подсетей
# =============================================================================
module "vpc" {
  source    = "../modules/vpc"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  vpc_name  = var.vpc_name

  # CIDR-блоки для разных типов подсетей
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  mgmt_subnet_cidrs    = var.mgmt_subnet_cidrs

  # NAT-шлюз для приватных подсетей
  enable_nat       = true
  nat_gateway_name = var.nat_gateway_name

  # Приватный эндпоинт для Object Storage (S3)
  s3_private_endpoint = {
    enable = true
    zone   = "ru-central1-d"
    name   = "s3-private-endpoint"
  }
}
# =============================================================================
# Модуль Security Groups — правила firewall для K8s, бастиона и внешних узлов
# =============================================================================
module "security_group" {
  source = "../modules/security-group"

  folder_id  = var.folder_id
  network_id = module.vpc.vpc_id

  security_groups = {

    # -------------------------------------------------------------------------
    # Бастион / NAT-инстанс — SSH из интернета
    # -------------------------------------------------------------------------
    "sg-bastion" = {
      description = "Security group для бастиона и NAT-инстанса"
      ingress = [
        {
          protocol       = "TCP"
          description    = "SSH из интернета"
          port           = 22
          v4_cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol       = "ICMP"
          description    = "ICMP для диагностики"
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress = [
        {
          protocol       = "ANY"
          description    = "Разрешить весь исходящий трафик"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    # -------------------------------------------------------------------------
    # Managed K8s — мастер и узлы
    # -------------------------------------------------------------------------
    "sg-k8s-main" = {
      description = "Основные правила для Managed K8s: API, etcd, Cilium, kubelet"
      ingress = [
        {
          protocol       = "TCP"
          description    = "Kubernetes API (443)"
          port           = 443
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol       = "TCP"
          description    = "Kubernetes API (6443)"
          port           = 6443
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol          = "TCP"
          description       = "Взаимодействие мастер-узел и узел-узел"
          predefined_target = "self_security_group"
        },
        {
          protocol          = "UDP"
          description       = "Cilium VXLAN"
          port              = 8472
          predefined_target = "self_security_group"
        },
        {
          protocol       = "TCP"
          description    = "kubelet (10250)"
          port           = 10250
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol       = "TCP"
          description    = "etcd (2379-2380)"
          from_port      = 2379
          to_port        = 2380
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol       = "ICMP"
          description    = "ICMP для диагностики"
          v4_cidr_blocks = ["10.0.0.0/16"]
        }
      ]
      egress = [
        {
          protocol       = "ANY"
          description    = "Разрешить весь исходящий трафик"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }

    # -------------------------------------------------------------------------
    # Внешние узлы K8s — дополнительный трафик
    # -------------------------------------------------------------------------
    "sg-k8s-workers" = {
      description = "Правила для внешних worker-узлов, подключаемых к Managed K8s"
      ingress = [
        {
          protocol       = "TCP"
          description    = "kubelet для связи с мастером"
          port           = 10250
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol       = "TCP"
          description    = "NodePort-сервисы"
          from_port      = 30000
          to_port        = 32767
          v4_cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol       = "UDP"
          description    = "Cilium VXLAN"
          port           = 8472
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
        {
          protocol       = "ICMP"
          description    = "ICMP для диагностики"
          v4_cidr_blocks = ["10.0.0.0/16"]
        }
      ]
      egress = [
        {
          protocol       = "ANY"
          description    = "Разрешить весь исходящий трафик"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
}