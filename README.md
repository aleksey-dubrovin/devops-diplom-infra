# Дипломный практикум в Yandex.Cloud — Инфраструктура

========================================================

## Описание проекта

Данный проект представляет собой инфраструктуру Yandex Cloud, развертываемую с помощью Terraform в соответствии с принципами Infrastructure as Code (IaC).

Инфраструктура включает:
- Сервисный аккаунт с набором ролей (IAM)
- S3-совместимое хранилище (Object Storage) для хранения состояния Terraform
- Сетевая инфраструктура: VPC, публичные/приватные/управляющие подсети, NAT-шлюз
- Приватный эндпоинт для Object Storage (S3)
- Security Groups с правилами firewall для K8s, бастиона и внешних узлов
- Удалённый бэкенд для хранения tfstate в Yandex Object Storage
- Автоматизированный CI/CD пайплайн через GitHub Actions

Проект реализован в виде модульной архитектуры, что обеспечивает переиспользование компонентов, разделение ответственности и упрощение поддержки.

## Цели и задачи

- Автоматизация развертывания инфраструктуры Yandex Cloud
- Обеспечение воспроизводимости и версионирования инфраструктуры
- Разделение инфраструктуры на логические модули для удобства поддержки
- Соблюдение принципов безопасности при работе с учетными данными
- Автоматизация применения изменений через CI/CD

## Архитектура

Проект состоит из двух уровней Terraform и CI/CD пайплайна:

```
devops-diplom-infra/
├── backend/                    # Уровень 1: создание SA + Storage (локальный state)
│   ├── main.tf                 # Провайдер + вызов модулей iam и storage
│   ├── variables.tf            # Глобальные переменные
│   ├── outputs.tf              # Выходные параметры (bucket, keys, sa_id)
│   ├── terraform.tfvars        # Значения переменных (не в VCS)
│   └── terraform.tfstate       # Состояние (не в VCS)
├── modules/
│   ├── iam/                    # Модуль: сервисный аккаунт и роли
│   │   ├── main.tf             # SA + data source + folder_iam_member
│   │   ├── variables.tf        # sa_name, folder_id, roles, create_sa
│   │   ├── outputs.tf          # service_account_id
│   │   └── versions.tf         # required_providers
│   ├── storage/                # Модуль: S3-бакет и ключи доступа
│   │   ├── main.tf             # bucket + access_key
│   │   ├── variables.tf        # bucket_name, sa_id, versioning
│   │   ├── outputs.tf          # bucket_name, access_key, secret_key
│   │   └── versions.tf         # required_providers
│   ├── vpc/                    # Модуль: VPC, подсети, NAT, S3-эндпоинт
│   │   ├── main.tf             # VPC + подсети + NAT + S3 endpoint
│   │   ├── variables.tf        # vpc_name, CIDRs, NAT, S3 config
│   │   ├── outputs.tf          # vpc_id, subnet_ids, nat_id, endpoint_id
│   │   └── versions.tf         # required_providers
│   └── security-group/         # Модуль: Security Groups с правилами firewall
│       ├── main.tf             # Динамическое создание SG с ingress/egress
│       ├── variables.tf        # security_groups (карта с правилами)
│       ├── outputs.tf          # security_group_ids, security_group_names
│       └── versions.tf         # required_providers
├── infrastructure/             # Уровень 2: удалённый S3-бэкенд + VPC + SG
│   ├── backend.tf              # terraform backend s3
│   ├── backend.tfvars          # Секреты S3 (не в VCS)
│   ├── main.tf                 # Провайдер + модули VPC и Security Groups
│   ├── variables.tf            # access_key, secret_key, sa_key, cloud_id, folder_id, VPC, подсети, NAT
│   ├── outputs.tf              # vpc_id, subnet_ids, nat_id, endpoint_id, sg_ids
│   └── .terraform/             # Состояние и провайдеры (не в VCS)
├── .github/workflows/
│   └── infrastructure.yml      # CI/CD: Plan (PR) + Apply (main)
├── .gitignore                  # Исключения для Git
└── README.md                   # Документация
```

## Используемые технологии

| Технология | Назначение |
|---|---|
| Terraform >= 1.3.0 | Оркестрация инфраструктуры (IaC) |
| Yandex Cloud Provider >= 0.9 | Провайдер для управления ресурсами Yandex Cloud |
| Yandex Object Storage | Удалённый бэкенд для хранения состояния Terraform |
| GitHub Actions | CI/CD: Plan для PR, Apply для main |
| Git | Контроль версий конфигурации |

## Описание модулей

### Модуль IAM (`modules/iam/`)

Модуль управляет сервисными аккаунтами и их ролями в Yandex Cloud.

**Функциональность:**
- Создание нового сервисного аккаунта или использование существующего (`create_sa`)
- Назначение ролей в указанной папке Yandex Cloud
- Поддержка динамического списка ролей

**Ресурсы:**
- `yandex_iam_service_account` — сервисный аккаунт (`count = create_sa ? 1 : 0`)
- `data.yandex_iam_service_account` — загрузка существующего аккаунта
- `yandex_resourcemanager_folder_iam_member` — назначение ролей

**Входные параметры:**

| Параметр | Тип | Описание | По умолчанию |
|---|---|---|---|
| `sa_name` | string | Имя сервисного аккаунта | — |
| `folder_id` | string | ID папки Yandex Cloud | — |
| `roles` | list(string) | Список ролей | `["editor", "storage.editor"]` |
| `create_sa` | bool | Создавать новый аккаунт | `false` |

**Выходные параметры:**

| Параметр | Описание |
|---|---|
| `service_account_id` | ID сервисного аккаунта |

### Модуль Storage (`modules/storage/`)

Модуль создаёт S3-совместимое хранилище и ключи доступа.

**Функциональность:**
- Создание бакета с уникальным именем (с добавлением folder_id)
- Генерация статического ключа доступа для S3 API
- Версионирование объектов
- Принудительное удаление бакета с объектами

**Ресурсы:**
- `yandex_storage_bucket` — S3-бакет с версионированием
- `yandex_iam_service_account_static_access_key` — статический ключ доступа

**Входные параметры:**

| Параметр | Тип | Описание | По умолчанию |
|---|---|---|---|
| `bucket_name` | string | Уникальное имя бакета | — |
| `service_account_id` | string | ID сервисного аккаунта | — |
| `enable_versioning` | bool | Включить версионирование | `true` |
| `force_destroy` | bool | Разрешить удаление с объектами | `true` |

**Выходные параметры:**

| Параметр | Описание |
|---|---|
| `bucket_name` | Имя созданного бакета |
| `access_key` | Access Key для S3 API |
| `secret_key` | Secret Key для S3 API |

### Модуль VPC (`modules/vpc/`)

Модуль создаёт сетевую инфраструктуру: VPC, подсети, NAT-шлюз и приватный эндпоинт для S3.

**Функциональность:**
- Создание VPC с тремя типами подсетей (публичные, приватные, управляющие)
- Настройка NAT-шлюза для исходящего трафика из приватных подсетей
- Создание приватного эндпоинта для Object Storage (S3)
- Поддержка трёх зон доступности (ru-central1-a, b, d)

**Ресурсы:**
- `yandex_vpc_network` — виртуальная частная сеть
- `yandex_vpc_subnet` (public) — публичные подсети (3 зоны)
- `yandex_vpc_subnet` (private) — приватные подсети с NAT (3 зоны)
- `yandex_vpc_subnet` (mgmt) — управляющие подсети для Managed K8s (3 зоны)
- `yandex_vpc_gateway` — NAT-шлюз (опционально)
- `yandex_vpc_route_table` — таблица маршрутизации для NAT
- `yandex_vpc_private_endpoint` — приватный эндпоинт для S3

**Входные параметры:**

| Параметр | Тип | Описание | По умолчанию |
|---|---|---|---|
| `vpc_name` | string | Имя VPC | `diplom-vpc` |
| `public_subnet_cidrs` | map(string) | CIDR публичных подсетей | — |
| `private_subnet_cidrs` | map(string) | CIDR приватных подсетей | — |
| `mgmt_subnet_cidrs` | map(string) | CIDR управляющих подсетей | — |
| `enable_nat` | bool | Создать NAT-шлюз | `true` |
| `nat_gateway_name` | string | Имя NAT-шлюза | `diplom-nat-gw` |
| `s3_private_endpoint` | object | Настройки S3-эндпоинта | `{enable=false, zone=ru-central1-d, name=s3-private-endpoint}` |

**CIDR-блоки по умолчанию:**

| Тип подсети | ru-central1-a | ru-central1-b | ru-central1-d |
|---|---|---|---|
| **Публичные** | `10.0.1.0/24` | `10.0.2.0/24` | `10.0.3.0/24` |
| **Приватные** | `10.0.4.0/24` | `10.0.5.0/24` | `10.0.6.0/24` |
| **Управляющие** | `10.0.7.0/24` | `10.0.8.0/24` | `10.0.9.0/24` |

**Выходные параметры:**

| Параметр | Описание |
|---|---|
| `vpc_id` | ID созданной VPC |
| `public_subnet_ids` | ID публичных подсетей (по зонам) |
| `private_subnet_ids` | ID приватных подсетей (по зонам) |
| `mgmt_subnet_ids` | ID управляющих подсетей (по зонам) |
| `nat_gateway_id` | ID NAT-шлюза (если создан) |
| `route_table_id` | ID таблицы маршрутизации (если создана) |
| `s3_private_endpoint_id` | ID приватного эндпоинта S3 (если создан) |

### Модуль Security Groups (`modules/security-group/`)

Модуль создаёт Security Groups с правилами ingress и egress для управления сетевой безопасностью.

**Функциональность:**
- Динамическое создание Security Groups с произвольным набором правил
- Поддержка правил ingress и egress с различными протоколами (TCP, UDP, ICMP, ANY)
- Поддержка CIDR-блоков, predefined_target и security_group_id
- Поддержка диапазонов портов (from_port/to_port) и одиночных портов

**Ресурсы:**
- `yandex_vpc_security_group` — Security Group с динамическими правилами ingress/egress

**Входные параметры:**

| Параметр | Тип | Описание |
|---|---|---|
| `folder_id` | string | ID папки Yandex Cloud |
| `network_id` | string | ID VPC, к которой привязаны SG |
| `security_groups` | map(object) | Карта SG с правилами ingress и egress |

**Формат security_groups:**
```hcl
security_groups = {
  "sg-name" = {
    description = "Описание группы"
    ingress = [
      {
        protocol       = "TCP"
        description    = "Описание правила"
        port           = 22
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
}
```

**Выходные параметры:**

| Параметр | Описание |
|---|---|
| `security_group_ids` | Карта ID созданных SG (ключ — имя группы) |
| `security_group_names` | Карта имён созданных SG |

### Backend (`backend/`) — Уровень 1

Главный файл конфигурации, создающий сервисный аккаунт и S3-бакет.

**Функциональность:**
- Настройка провайдера Yandex Cloud
- Вызов модулей IAM и Storage
- Передача `service_account_id` из IAM в Storage (dependency injection)

**Назначаемые роли:**

| Роль | Описание |
|---|---|
| `editor` | Полный доступ к ресурсам в папке |
| `storage.editor` | Управление хранилищем Object Storage |
| `container-registry.admin` | Администрирование Yandex Container Registry |
| `dns.editor` | Управление DNS-записями |

### Infrastructure (`infrastructure/`) — Уровень 2

Конфигурация удалённого бэкенда для хранения состояния Terraform в Yandex Object Storage + вызов модулей VPC и Security Groups.

**Функциональность:**
- Настройка S3-совместимого бэкенда с endpoint `storage.yandexcloud.net`
- Вызов модуля VPC для создания сетевой инфраструктуры
- Вызов модуля Security Groups для настройки firewall
- Параметры совместимости: `skip_region_validation`, `skip_credentials_validation`, `use_path_style`
- Хранение `infra.tfstate` в указанном бакете

**Параметры бэкенда:**

| Параметр | Описание |
|---|---|
| `bucket` | Имя бакета для хранения tfstate |
| `key` | Путь к файлу состояния (`infra.tfstate`) |
| `region` | Регион (`ru-central1`) |
| `use_path_style` | URL-стиль (`true`) |
| `skip_region_validation` | Пропуск проверки региона (`true`) |
| `skip_credentials_validation` | Пропуск валидации учётных данных (`true`) |
| `skip_requesting_account_id` | Пропуск запроса ID аккаунта (`true`) |
| `skip_s3_checksum` | Пропуск проверки контрольной суммы (`true`) |

**Security Groups в infrastructure/main.tf:**

| Группа | Описание | Правила |
|---|---|---|
| `sg-bastion` | Бастион / NAT-инстанс | SSH (22) из интернета, ICMP для диагностики, весь исходящий |
| `sg-k8s-main` | Managed K8s — мастер и узлы | API (443, 6443), kubelet (10250), etcd (2379-2380), Cilium VXLAN (8472), ICMP |
| `sg-k8s-workers` | Внешние worker-узлы K8s | kubelet (10250), NodePort (30000-32767), Cilium VXLAN (8472), ICMP |

## CI/CD пайплайн (GitHub Actions)

### Workflow: `infrastructure.yml`

Автоматизированное развёртывание инфраструктуры при изменении файлов в `infrastructure/`.

**Триггеры:**
| Событие | Действие |
|---|---|
| `push` в `main` | `terraform apply` |
| `pull_request` в `main` | `terraform plan` (без применения) |
| `workflow_dispatch` | Ручной запуск из интерфейса GitHub |

**Jobs:**

| Job | Описание | Условие запуска |
|---|---|---|
| `terraform-plan` | Проверка плана изменений | `pull_request` |
| `terraform-apply` | Применение изменений | `push` на