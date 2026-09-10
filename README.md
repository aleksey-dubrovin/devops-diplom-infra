# Дипломный практикум в Yandex.Cloud — Инфраструктура

========================================================

## Описание проекта

Данный проект представляет собой инфраструктуру Yandex Cloud, развертываемую с помощью Terraform в соответствии с принципами Infrastructure as Code (IaC).

Инфраструктура включает:
- Сервисный аккаунт с набором ролей (IAM)
- S3-совместимое хранилище (Object Storage) для хранения состояния Terraform
- Удалённый бэкенд для хранения tfstate в Yandex Object Storage
- Сетевая инфраструктура: VPC, публичные/приватные/управляющие подсети, NAT-шлюз
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
│   └── vpc/                    # Модуль: VPC, подсети, NAT, S3-эндпоинт
│       ├── main.tf             # VPC + подсети + NAT + S3 endpoint
│       ├── variables.tf        # vpc_name, CIDRs, NAT, S3 config
│       ├── outputs.tf          # vpc_id, subnet_ids, nat_id, endpoint_id
│       └── versions.tf         # required_providers
├── infrastructure/             # Уровень 2: удалённый S3-бэкенд + VPC
│   ├── backend.tf              # terraform backend s3
│   ├── backend.tfvars          # Секреты S3 (не в VCS)
│   ├── main.tf                 # Провайдер + модуль VPC
│   ├── variables.tf            # access_key, secret_key, sa_key, cloud_id, folder_id, VPC, подсети, NAT
│   ├── outputs.tf              # vpc_id, subnet_ids, nat_id, endpoint_id
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

Конфигурация удалённого бэкенда для хранения состояния Terraform в Yandex Object Storage + вызов модуля VPC.

**Функциональность:**
- Настройка S3-совместимого бэкенда с endpoint `storage.yandexcloud.net`
- Вызов модуля VPC для создания сетевой инфраструктуры
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
| `terraform-apply` | Применение изменений | `push` на `main` |

**Кэш плагинов:**
- `actions/cache@v4` — кэширует `.terraform` по хэшу `.tf` файлов
- Ключ: `${runner.os}-terraform-${hashFiles(...)}`

**Передача секретов:**
- `YC_ACCESS_KEY` / `YC_SECRET_KEY` — ключи S3-бэкенда
- `YC_SERVICE_ACCOUNT_KEY` — JSON-ключ сервисного аккаунта
- `YC_CLOUD_ID` / `YC_FOLDER_ID` — идентификаторы облака

## Безопасность

- Чувствительные данные (`token`, `cloud_id`, `folder_id`, ключи доступа) помечены как `sensitive`
- Файлы `.tfstate`, `.tfvars`, `.terraform/` исключены из системы контроля версий (`.gitignore`)
- Статические ключи генерируются автоматически при создании бакета
- Версионирование бакета обеспечивает защиту от потери состояния
- Секреты GitHub Actions передаются через `secrets.*`, не попадают в логи

## Требования

- Terraform >= 1.3.0 (используется 1.12.2)
- Аккаунт Yandex Cloud
- IAM-токен или JSON-ключ сервисного аккаунта
- Настроенный GitHub Actions с секретами

## Быстрый старт

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd devops-diplom-infra
```

### 2. Настройка переменных

Создайте файл `backend/terraform.tfvars`:

```hcl
yandex_token = "your-yandex-token"
cloud_id     = "your-cloud-id"
folder_id    = "your-folder-id"
sa_name      = "your-service-account-name"
bucket_name  = "tfstate-diplom"
```

Получить токен можно в [консоли Yandex Cloud](https://console.yandex.cloud/iam/token).

### 3. Развёртывание инфраструктуры (Уровень 1)

```bash
cd backend
terraform init
terraform plan    # Предпросмотр изменений
terraform apply   # Создание SA + Storage
```

### 4. Настройка удалённого бэкенда и VPC (Уровень 2)

После создания бакета настройте `infrastructure/`:

```bash
cd infrastructure
terraform init \
  -backend-config="access_key=<access_key>" \
  -backend-config="secret_key=<secret_key>"
terraform plan    # Проверка плана VPC
terraform apply   # Создание VPC, подсетей, NAT, S3-эндпоинта
```

### 5. CI/CD

- Создайте PR с изменениями в `infrastructure/` — запустится `terraform plan`
- После мержа в `main` — автоматически запустится `terraform apply`
- Ручной запуск: Actions → Deploy Infrastructure → Run workflow

### 6. Уничтожение

```bash
# Уровень 1
cd backend && terraform destroy

# Уровень 2
cd infrastructure && terraform destroy
```

## Использование ключей доступа

Полученные ключи можно использовать для работы с хранилищем через S3-совместимый API:

```bash
export ACCESS_KEY_ID=<access_key>
export SECRET_ACCESS_KEY=<secret_key>
export DEFAULT_REGION=ru-central1

# Пример: список объектов в бакете
aws --endpoint-url https://storage.yandexcloud.net s3 ls s3://<bucket-name>/
```

## Структура состояний

Проект использует двухуровневую архитектуру состояний:

| Уровень | Состояние | Хранилище |
|---|---|---|
| **Backend** (Уровень 1) | `backend/terraform.tfstate` | Локально |
| **Infrastructure** (Уровень 2) | `infra.tfstate` | Yandex Object Storage (S3) |

Состояние первого уровня хранится локально и содержит информацию о сервисном аккаунте и бакете. Состояние второго уровня хранится в удалённом S3-бэкенде и предназначено для будущей масштабируемой инфраструктуры.

## Визуализация инфраструктуры

Для визуализации зависимостей между ресурсами:

```bash
terraform graph | dot -Tpng > infrastructure.png
```

## Известные ограничения

- Состояние первого уровня хранится локально
- Сервисный аккаунт используется существующий (`create_sa = false`)
- Роли назначаются на уровне папки (`folder`), а не облака (`cloud`)
- Бэкенд второго уровня не использует шифрование на стороне сервера

## Лицензия

Данный проект является частью дипломного практикума и предназначен исключительно для образовательных целей.
