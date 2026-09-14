
# Дипломный практикум в Yandex.Cloud - Инфраструктура

## Назначение

Данный модуль описывает полную сетевую инфраструктуру и кластер **Managed Kubernetes** в **Yandex Cloud** с использованием **Terraform**. Проект предназначен для развёртывания отказоустойчивого, многозонального Kubernetes-окружения с продуманной сетевой архитектурой, управлением доступом и автоматизированным CI/CD-конвейером.

Проект является частью дипломного практикума по DevOps в Yandex.Cloud.

---

## Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                       Yandex Cloud (ru-central1)                │
│                                                                 │
│  ┌─────────────────── VPC: diplom-vpc ─────────────────────┐   │
│  │                                                         │   │
│  │  Zone A        Zone B        Zone D                    │   │
│  │  ─────         ─────         ─────                     │   │
│  │  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐         │   │
│  │  │Pub  │  │Pub  │  │Pub  │  │Prv  │  │Prv  │  │Prv  │  │   │
│  │  │Sub  │  │Sub  │  │Sub  │  │Sub  │  │Sub  │  │Sub  │  │   │
│  │  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  │   │
│  │  ┌─────┐  ┌─────┐  ┌─────┐                               │   │
│  │  │Mgmt │  │Mgmt │  │Mgmt │                               │   │
│  │  └─────┘  └─────┘  └─────┘                               │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  Yandex Managed Kubernetes Cluster (Regional)   │   │   │
│  │  │  Master: 3 zones (A, B, D) · etcd×3 · Cilium    │   │   │
│  │  │  Network Policy: Cilium (tunnel mode)           │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  NAT-шлюз (Shared Egress) → приватные подсети           │   │
│  │  Private Endpoint → Yandex Object Storage (S3)          │   │
│  │                                                         │   │
│  │  Security Groups:                                       │   │
│  │    • sg-bastion    — SSH/ICMP для бастиона              │   │
│  │    • sg-k8s-main   — API, etcd, kubelet, Cilium         │   │
│  │    • sg-k8s-workers — NodePort, kubelet, Cilium         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Сетевая схема

| Тип подсети     | Zone A       | Zone B       | Zone D       | Назначение                    |
|-----------------|-------------|-------------|-------------|-------------------------------|
| **Публичная**   | 10.0.1.0/24 | 10.0.2.0/24 | 10.0.3.0/24 | Виртуальные машины с публичным IP |
| **Приватная**   | 10.0.4.0/24 | 10.0.5.0/24 | 10.0.6.0/24 | Внешние worker-узлы K8s       |
| **Управляющая** | 10.0.7.0/24 | 10.0.8.0/24 | 10.0.9.0/24 | Managed K8s master-ноды       |

---

## Структура проекта

```
devops-diplom-infra/
├── .github/workflows/
│   └── infrastructure.yml          # CI/CD: Terraform Plan + Apply через GitHub Actions
├── .gitignore
├── LICENSE
├── README.md
├── backend/                        # Модуль бэкенда: IAM + S3-бакет для state
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── infrastructure/                 # Основной модуль инфраструктуры
│   ├── main.tf                     # Провайдер, вызов модулей VPC, SG, K8s, IAM
│   ├── variables.tf                # Входные переменные
│   ├── outputs.tf                  # Выходные данные
│   ├── backend.tf                  # S3-бэкенд для хранения state
│   ├── backend.tfvars              # Секреты S3-бэкенда
│   └── terraform.tfvars            # Переменные инфраструктуры
└── modules/                        # Переиспользуемые Terraform-модули
    ├── iam/                        # Сервисные аккаунты и роли
    ├── k8s-cluster/                # Managed Kubernetes кластер
    ├── security-group/             # Security groups с правилами firewall
    ├── storage/                    # S3-бакет + статический ключ доступа
    └── vpc/                        # VPC, подсети, NAT-шлюз, приватный эндпоинт S3
```

---

## Компоненты инфраструктуры

### 1. VPC и сети (`modules/vpc`)

Создаёт полноценную сетевую инфраструктуру:

- **VPC** — виртуальная частная сеть с именем `diplom-vpc`
- **Публичные подсети** — по одной на каждую зону (A, B, D), для ВМ с публичным IP
- **Приватные подсети** — по одной на каждую зону, с маршрутизацией через NAT-шлюз
- **Управляющие подсети** — по одной на каждую зону, для мастер-нод Managed Kubernetes
- **NAT-шлюз** — Shared Egress Gateway для исходящего трафика из приватных подсетей
- **Приватный эндпоинт Object Storage (S3)** — доступ к хранилищу через внутреннюю сеть Yandex Cloud (zone: ru-central1-d)

### 2. Security Groups (`modules/security-group`)

Три группы безопасности с детальными правилами ingress/egress:

| Группа           | Описание                                              |
|------------------|-------------------------------------------------------|
| `sg-bastion`     | SSH (22) и ICMP из интернета; весь исходящий трафик   |
| `sg-k8s-main`    | Kubernetes API (443, 6443), etcd (2379-2380), kubelet (10250), Cilium VXLAN (8472), ICMP |
| `sg-k8s-workers` | kubelet (10250), NodePort (30000-32767), Cilium VXLAN (8472), ICMP |

### 3. Managed Kubernetes (`modules/k8s-cluster`)

Региональный кластер Kubernetes с высокой доступностью:

- **Мастер**: региональный (3 зоны: A, B, D), 3 экземпляра etcd
- **Версия**: Kubernetes 1.35, канал обновлений STABLE
- **Сетевой стэк**: Cilium в туннельном режиме (поддержка внешних узлов)
- **Публичный доступ**: включён (для упрощения; в продакшене рекомендуется отключить)
- **Автоматическое обновление**: включено
- **Окно обслуживания**: понедельник, 23:00, длительность 3 часа
- **Сервисный аккаунт**: роли `k8s.clusters.agent`, `k8s.tunnelClusters.agent`, `vpc.publicAdmin`, `container-registry.images.puller`, `monitoring.editor`, `storage.editor`, `dns.editor`

### 4. IAM (`modules/iam`)

Управление сервисными аккаунтами:

- Создание или использование существующего SA (управляется флагом `create_sa`)
- Назначение ролей в папке через `yandex_resourcemanager_folder_iam_member`

### 5. Storage (`modules/storage`)

S3-совместимое хранилище для бэкенда Terraform:

- Создание бакета с версионированием
- Генерация статического ключа доступа (Access Key / Secret Key)

### 6. Backend (`backend/`)

Отдельный модуль для подготовки инфраструктуры бэкенда:

- Создаёт сервисный аккаунт с ролями `editor`, `storage.editor`, `container-registry.admin`, `dns.editor`
- Создаёт S3-бакет для хранения `*.tfstate` файлов
- Выходные данные: имя бакета, access key, secret key, ID SA

---

## CI/CD — GitHub Actions

Файл: `.github/workflows/infrastructure.yml`

### Триггеры

| Событие              | Действие              | Описание                          |
|----------------------|-----------------------|-----------------------------------|
| Push в `main`        | `terraform apply`     | Автоматическое применение изменений |
| Pull Request         | `terraform plan`      | Предпросмотр плана без применения  |
| `workflow_dispatch`  | Ручной запуск         | Ручной запуск из интерфейса GitHub |

### Jobs

1. **`terraform-plan`** — генерирует план изменений (только PR)
2. **`terraform-apply`** — применяет изменения (только push в main)

### Секреты (GitHub Secrets)

| Секрет                      | Описание                          |
|-----------------------------|-----------------------------------|
| `YC_SERVICE_ACCOUNT_KEY`    | JSON-ключ SA (base64-кодированный)|
| `YC_ACCESS_KEY`             | Access Key для S3-бэкенда         |
| `YC_SECRET_KEY`             | Secret Key для S3-бэкенда         |
| `YC_CLOUD_ID`               | ID облака Yandex Cloud            |
| `YC_FOLDER_ID`              | ID папки Yandex Cloud             |
| `K8S_SERVICE_ACCOUNT_ID`    | ID SA для мастера K8s             |
| `K8S_NODE_SERVICE_ACCOUNT_ID`| ID SA для нод K8s                |
| `K8S_SA_NAME`               | Имя SA для K8s                    |
| `TF_BUCKET_NAME`            | Имя бакета для state              |

---

## Переменные

### Основные (infrastructure/)

| Переменная                   | Тип         | По умолчанию             | Описание                        |
|------------------------------|-------------|--------------------------|---------------------------------|
| `cloud_id`                   | string      | —                        | ID облака                       |
| `folder_id`                  | string      | —                        | ID папки                        |
| `vpc_name`                   | string      | `diplom-vpc`             | Имя VPC                         |
| `k8s_cluster_version`        | string      | `1.35`                   | Версия Kubernetes               |
| `k8s_release_channel`        | string      | `STABLE`                 | Канал обновлений                |
| `default_zone`               | string      | `ru-central1-d`          | Зона по умолчанию               |
| `k8s_create_sa`              | bool        | `false`                  | Создавать новый SA              |

### Сетевые

| Переменная                   | Тип         | По умолчанию                        | Описание              |
|------------------------------|-------------|-------------------------------------|-----------------------|
| `public_subnet_cidrs`        | map(string) | A: 10.0.1.0/24, B: 10.0.2.0/24, D: 10.0.3.0/24 | Публичные подсети   |
| `private_subnet_cidrs`       | map(string) | A: 10.0.4.0/24, B: 10.0.5.0/24, D: 10.0.6.0/24 | Приватные подсети   |
| `mgmt_subnet_cidrs`          | map(string) | A: 10.0.7.0/24, B: 10.0.8.0/24, D: 10.0.9.0/24 | Управляющие подсети |

### Секретные

| Переменная                   | Описание                          |
|------------------------------|-----------------------------------|
| `service_account_key_file`   | Путь к JSON-файлу ключа SA        |
| `access_key`                 | Access Key для S3-бэкенда         |
| `secret_key`                 | Secret Key для S3-бэкенда         |

---

## Выходные данные (Outputs)

| Выход                       | Описание                                |
|-----------------------------|-----------------------------------------|
| `vpc_id`                    | ID созданной VPC                        |
| `public_subnet_ids`         | ID публичных подсетей (по зонам)        |
| `private_subnet_ids`        | ID приватных подсетей (по зонам)        |
| `mgmt_subnet_ids`           | ID управляющих подсетей (по зонам)      |
| `nat_gateway_id`            | ID NAT-шлюза                            |
| `s3_private_endpoint_id`    | ID приватного эндпоинта Object Storage  |
| `security_group_ids`        | Карта ID security групп                 |
| `k8s_cluster_id`            | ID кластера Kubernetes                  |
| `k8s_cluster_endpoint`      | Внутренний endpoint кластера            |
| `k8s_service_account_id`    | ID сервисного аккаунта для K8s          |

---

## Версионирование

Проект использует теги для фиксации состояний инфраструктуры:

| Тег                | Описание                                    |
|--------------------|---------------------------------------------|
| `v0.1.0`           | Начальная версия                            |
| `v0.2.0-backend-s3`| Добавлен backend-модуль (IAM + S3)          |
| `v0.2.1-backend-s3`| Улучшения backend-модуля                    |
| `v0.3.0-vpc`       | Добавлен VPC-модуль                         |
| `v0.3.1-vpc`       | Улучшения VPC-модуля                        |
| `v0.4.0-security-groups` | Добавлены security groups             |

---

## Требования

- **Terraform**: >= 1.3.0 (рекомендуется 1.12.2)
- **Провайдер**: `yandex-cloud/yandex` > 0.9
- **Yandex Cloud**: регион `ru-central1`
- Доступ к Yandex Cloud API (через JSON-ключ SA или токен)

---

## Использование

### 1. Подготовка бэкенда (один раз)

```bash
cd backend
terraform init
terraform apply
```

### 2. Развёртывание инфраструктуры

```bash
cd infrastructure
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Проверка через GitHub Actions

```bash
# Создать PR с изменениями в infrastructure/
# GitHub Actions автоматически выполнит terraform plan
# После мержа в main — terraform apply
```

---

## Лицензия

MIT License — Copyright (c) 2026 Алексей Дубровин
