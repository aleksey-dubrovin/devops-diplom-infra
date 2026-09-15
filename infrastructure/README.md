# Infrastructure — Yandex Cloud + Managed Kubernetes

## Обзор

Данный проект описывает **полную инфраструктуру** в Yandex Cloud с использованием **Terraform**. Инфраструктура включает:

- Сеть VPC с разделением на публичные, приватные и управляющие подсети
- Managed Kubernetes кластер с туннельным режимом Cilium
- Внешние worker-узлы, подключаемые к Managed K8s через NodeGroup
- Security Groups с детализированными правилами firewall
- Bastion-хост для безопасного доступа
- NAT-шлюз для исходящего трафика из приватных подсетей
- Приватный эндпоинт для Yandex Object Storage (S3)
- State-файл хранится в S3-бакете для совместной работы

## Архитектура

```plain
┌─────────────────────────────────────────────────────────────┐
│                        Yandex Cloud                          │
│  Cloud: b1g5akar41n0hohkvoq7                                │
│  Folder: b1glfq89j9n7quk0cnf0                               │
│  Region: ru-central1                                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    VPC (diplom-vpc)                    │   │
│  │                                                      │   │
│  │  Public (10.0.1/2/3/24)    Private (10.0.4/5/6/24)   │   │
│  │       │                         │                     │   │
│  │  ┌────┴────┐              ┌────┴────┐                │   │
│  │  │Bastion  │              │ Workers │                │   │
│  │  │NAT-GW   │              │(external│                │   │
│  │  │         │              │ nodes)  │                │   │
│  │  └─────────┘              └─────────┘                │   │
│  │                         Mgmt (10.0.7/8/9/24)          │   │
│  │                         ┌──────────────┐              │   │
│  │                         │Managed K8s   │              │   │
│  │                         │  Master (3)  │              │   │
│  │                         └──────────────┘              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты

### 1. Сеть (VPC)

Модуль `modules/vpc` создаёт сетевую инфраструктуру:

| Подсеть | CIDR (a) | CIDR (b) | CIDR (d) | Назначение |
|---------|----------|----------|----------|------------|
| Public | 10.0.1.0/24 | 10.0.2.0/24 | 10.0.3.0/24 | Публичные ресурсы (bastion) |
| Private | 10.0.4.0/24 | 10.0.5.0/24 | 10.0.6.0/24 | Worker-узлы, приватные сервисы |
| Mgmt | 10.0.7.0/24 | 10.0.8.0/24 | 10.0.9.0/24 | Управляющие подсети для K8s мастера |

**Особенности:**
- NAT-шлюз для исходящего интернета из приватных подсетей
- Приватный эндпоинт Object Storage (S3) в зоне `ru-central1-d`

### 2. Security Groups

Три группы безопасности:

| Группа | Назначение | Ключевые правила |
|--------|------------|------------------|
| `sg-bastion` | Bastion / NAT-инстанс | SSH (22) из интернета, ICMP, весь исходящий |
| `sg-k8s-main` | Managed K8s мастер | API (443, 6443), etcd (2379-2380), kubelet (10250), Cilium VXLAN (8472), healthchecks |
| `sg-k8s-workers` | Внешние worker-узлы | SSH, kubelet, NodePort (30000-32767), Cilium VXLAN |

### 3. Managed Kubernetes

Модуль `modules/k8s-cluster` разворачивает:

- **Региональный мастер** с 3 etcd-нодами (отказоустойчивость)
- **Туннельный режим Cilium** — позволяет подключать внешние узлы без прямого доступа к API
- **Канал обновлений:** STABLE
- **Версия:** 1.35
- **Публичный доступ:** включён (для удобства; в продакшене рекомендуется отключить)
- **Maintenance window:** понедельник 23:00–02:00

Мастер развёрнут в трёх зонах (`ru-central1-a/b/d`) в управляющих подсетях.

### 4. IAM / Сервисные аккаунты

Модуль `modules/iam` создаёт сервисный аккаунт с ролями:

| Роль | Назначение |
|------|------------|
| `k8s.clusters.agent` | Доступ к кластеру K8s |
| `k8s.tunnelClusters.agent` | Туннельный режим для внешних узлов |
| `vpc.publicAdmin` | Управление публичными IP |
| `container-registry.images.puller` | Pull образов из Container Registry |
| `monitoring.editor` | Редактирование мониторинга |
| `storage.editor` | Работа с хранилищами |
| `dns.editor` | Управление DNS |

### 5. Compute (Bastion + Workers)

Модуль `modules/compute` разворачивает:

- **Bastion-хост** — точка входа в инфраструктуру, SSH из интернета
- **Внешние worker-узлы** — в приватных подсетях (`ru-central1-a/b`), подключаются к K8s через NodeGroup

### 6. State Management

Состояние Terraform хранится в **Yandex Object Storage** (S3-совместимый API):

- **Бакет:** `devops-diplom-tf-b1glfq89j9n7quk0cnf0`
- **Ключ:** `infra.tfstate`
- **Эндпоинт:** `https://storage.yandexcloud.net`

Это позволяет нескольким разработчикам работать с одной инфраструктурой.

## Структура файлов

```
infrastructure/
├── main.tf                  # Основная конфигурация (модули)
├── variables.tf             # Описание переменных
├── outputs.tf               # Выходные значения
├── backend.tf               # Конфигурация S3-бэкенда
├── backend.tfvars           # Секреты для бэкенда (S3)
├── terraform.tfvars         # Значения переменных инфраструктуры
├── .terraform.lock.hcl      # Lock-файл провайдеров
├── templates/
│   └── nodegroup.yaml.tpl   # Шаблон NodeGroup для внешних узлов
├── modules/
│   ├── vpc/                 # Модуль сети
│   ├── security-group/      # Модуль Security Groups
│   ├── k8s-cluster/         # Модуль Managed Kubernetes
│   ├── iam/                 # Модуль IAM / SA
│   └── compute/             # Модуль Compute (bastion + workers)
└── README.md                # Этот файл
```

## Использование

### 1. Инициализация

```bash
terraform init
```

### 2. Применение

```bash
terraform apply -var-file="backend.tfvars" -var-file="terraform.tfvars"
```

### 3. Проверка состояния

```bash
terraform plan -var-file="backend.tfvars" -var-file="terraform.tfvars"
```

### 4. Уничтожение инфраструктуры

```bash
terraform destroy -var-file="backend.tfvars" -var-file="terraform.tfvars"
```

## Выходные данные (Outputs)

После применения Terraform доступны:

| Output | Описание |
|--------|----------|
| `vpc_id` | ID VPC |
| `public_subnet_ids` | ID публичных подсетей |
| `private_subnet_ids` | ID приватных подсетей |
| `mgmt_subnet_ids` | ID управляющих подсетей |
| `nat_gateway_id` | ID NAT-шлюза |
| `k8s_cluster_id` | ID K8s кластера |
| `k8s_cluster_endpoint` | Внутренний endpoint K8s |
| `k8s_cluster_external_endpoint` | Внешний endpoint K8s |
| `bastion_public_ip` | Публичный IP bastion |
| `bastion_ssh_command` | Команда для SSH к bastion |
| `worker_internal_ips` | Внутренние IP worker-узлов |
| `worker_ssh_commands_via_bastion` | Команды SSH к workers через bastion |
| `external_nodegroup_manifest` | YAML-манифест NodeGroup |

## Подключение внешних узлов

Внешние worker-узлы подключаются к Managed K8s через **NodeGroup** (MKS External Node Groups):

1. После применения Terraform получить манифест:
   ```bash
   terraform output -raw external_nodegroup_manifest > nodegroup.yaml
   ```

2. Применить манифест:
   ```bash
   kubectl apply -f nodegroup.yaml
   ```

3. На worker-узлы загрузить SSH-ключ в secret:
   ```bash
   kubectl create secret generic external-node-ssh-key \
     --namespace yandex-system \
     --from-file=ssh-privatekey=~/.ssh/key \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

## Безопасность

- **Секреты** (`access_key`, `secret_key`, `service_account_key_file`) не должны попадать в Git
- Файлы `*.tfvars` добавлены в `.gitignore`
- SSH-ключи хранятся локально и не разворачиваются в инфраструктуре
- Security Groups строго ограничивают входящий трафик

## Зависимости

| Компонент | Версия |
|-----------|--------|
| Terraform | ≥ 1.6.1 |
| Yandex Provider | 0.225.0 |
| Kubernetes | 1.35 (STABLE) |

## Примечания

- Проект использует **Yandex Cloud** (region: `ru-central1`)
- Managed K8s работает в **туннельном режиме** (Cilium)
- State-файл хранится в **Yandex Object Storage**
- Для работы требуется `kubectl` и `yandex-cloud` CLI