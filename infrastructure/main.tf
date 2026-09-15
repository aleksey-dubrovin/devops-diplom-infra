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
          protocol          = "TCP"
          description       = "Health checks от балансировщика"
          from_port         = 0
          to_port           = 65535
          predefined_target = "loadbalancer_healthchecks"
        },
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
          protocol          = "ANY"
          description       = "Взаимодействие мастер-узел и узел-узел"
          predefined_target = "self_security_group"
          from_port         = 0
          to_port           = 65535
        },
        {
          protocol          = "UDP"
          description       = "Cilium VXLAN"
          port              = 8472
          predefined_target = "self_security_group"
        },
        {
          protocol       = "TCP"
          description    = "SSH с bastion и мастер-узлов K8s"
          port           = 22
          v4_cidr_blocks = ["10.0.0.0/16"]
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
          description    = "ICMP из подсетей Yandex Cloud"
          v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
        },
        {
          protocol       = "ANY"
          description    = "Трафик к CIDR кластера (поды)"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["10.96.0.0/16", "10.112.0.0/16", "10.100.0.0/16", "10.101.0.0/16"]
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
          description    = "SSH с bastion и мастер-узлов K8s"
          port           = 22
          v4_cidr_blocks = ["10.0.0.0/16"]
        },
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
# =============================================================================
# Модуль Managed Kubernetes (региональный мастер, туннельный режим Cilium)
# =============================================================================
module "k8s_cluster" {
  source = "../modules/k8s-cluster"

  folder_id  = var.folder_id
  network_id = module.vpc.vpc_id
  service_account_id      = module.iam_k8s.service_account_id
  node_service_account_id = module.iam_k8s.service_account_id

  # Используем управляющие подсети (mgmt) в трёх зонах
  master_locations = [
    {
      zone      = "ru-central1-a"
      subnet_id = module.vpc.mgmt_subnet_ids["ru-central1-a"]
    },
    {
      zone      = "ru-central1-b"
      subnet_id = module.vpc.mgmt_subnet_ids["ru-central1-b"]
    },
    {
      zone      = "ru-central1-d"
      subnet_id = module.vpc.mgmt_subnet_ids["ru-central1-d"]
    }
  ]

  # Security group для K8s
  security_group_ids = [module.security_group.security_group_ids["sg-k8s-main"]]

  # Существующий сервисный аккаунт (тот же, что использовался для backend)
  #service_account_id      = var.k8s_service_account_id
  #node_service_account_id = var.k8s_node_service_account_id

  # Версия и канал обновлений
  cluster_version = var.k8s_cluster_version
  release_channel = var.k8s_release_channel

  # Туннельный режим (Cilium) для внешних узлов
  enable_cilium_policy = true

  # Публичный доступ к мастеру (для упрощения; в продакшене можно выключить)
  public_access = true

  # Размер etcd-кластера
  etcd_cluster_size = 3

  # Окна обслуживания (опционально)
  master_maintenance_windows = [
    {
      day        = "monday"
      start_time = "23:00"
      duration   = "3h"
    }
  ]
}
# =============================================================================
# Назначение дополнительных ролей сервисному аккаунту для K8s
# =============================================================================
module "iam_k8s" {
  source = "../modules/iam"

  folder_id = var.folder_id
  sa_name   = var.k8s_sa_name
  create_sa = var.k8s_create_sa 

  roles = [
    "k8s.clusters.agent",
    "k8s.tunnelClusters.agent",
    "vpc.publicAdmin",
    "container-registry.images.puller",
    "monitoring.editor",
    "storage.editor",
    "dns.editor",
  ]
}
# =============================================================================
# Модуль Compute — bastion и внешние worker-узлы
# =============================================================================
module "compute" {
  source = "../modules/compute"

  folder_id        = var.folder_id
  public_subnet_id = module.vpc.public_subnet_ids["ru-central1-d"]

  private_subnet_ids = {
    "ru-central1-a" = module.vpc.private_subnet_ids["ru-central1-a"]
    "ru-central1-b" = module.vpc.private_subnet_ids["ru-central1-b"]
  }

  security_group_ids = module.security_group.security_group_ids
  ssh_public_key     = file(var.ssh_public_key_path)
}
