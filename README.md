# Инфраструктура дипломного проекта в Yandex Cloud, описанная через Terraform.

Репозиторий отвечает только за инфраструктурный слой: сеть, Kubernetes
кластер, виртуальные машины, Container Registry, Audit Trails и Logging
Group. Конфигурация Kubernetes и код приложения лежат в отдельных
репозиториях.

## Связанные репозитории

- [devops-diplom-k8s](https://github.com/aleksey-dubrovin/devops-diplom-k8s) — манифесты Kubernetes и Helm-values
- [devops-diplom-app](https://github.com/aleksey-dubrovin/devops-diplom-app) — код тестового приложения и CI/CD

## Архитектура

Проект построен по модульному принципу. Каждый компонент инфраструктуры
вынесен в отдельный модуль в `modules/`, а корневой `infrastructure/main.tf`
собирает их вместе.

```
devops-diplom-infra/
├── backend/                    # создание S3-бакета для state
├── infrastructure/             # основная инфраструктура
│   ├── backend.tf              # настройка S3 backend
│   ├── main.tf                 # вызов модулей
│   ├── variables.tf
│   ├── outputs.tf
│   └── templates/              # шаблон NodeGroup
└── modules/
    ├── vpc/                    # сеть, подсети, NAT, S3 endpoint
    ├── security-group/         # правила firewall
    ├── iam/                    # сервисные аккаунты и роли
    ├── k8s-cluster/            # Managed Kubernetes
    ├── compute/                # bastion и worker-узлы
    └── observability/          # Audit Trails и Logging Group
```

## Что создаётся

| Ресурс | Модуль | Описание |
|--------|--------|----------|
| VPC и 9 подсетей | `vpc` | Public / private / mgmt в трёх зонах |
| NAT-шлюз | `vpc` | Исходящий интернет для приватных подсетей |
| Приватный endpoint S3 | `vpc` | Доступ к Object Storage без выхода в интернет |
| Security groups | `security-group` | `sg-bastion`, `sg-k8s-main`, `sg-k8s-workers` |
| Сервисный аккаунт и роли | `iam` | SA `avdubrovin-prod` с минимально необходимыми правами |
| Managed Kubernetes | `k8s-cluster` | Региональный мастер, 3 зоны, Cilium tunnel |
| Бастион и worker-ВМ | `compute` | 3 прерываемые ВМ: bastion, worker-a, worker-b |
| Container Registry | `infrastructure/main.tf` | `cr.yandex/crph52se6qjtjg937i7h` |
| NLB | `infrastructure/main.tf` | Публичный балансировщик на NodePort |
| Logging Group | `observability` | `diplom-k8s-logs` для логов кластера |
| Audit Trails | `observability` | `diplom-audit-trail` для аудита облака |

## Требования

- Terraform 1.12 или новее.
- Yandex Cloud CLI для первичной авторизации.
- Сервисный аккаунт с правами `editor` на уровне папки.
- Авторизованный JSON-ключ сервисного аккаунта.

## Развёртывание

### Шаг 1. Создание бэкенда

```bash
cd backend
terraform init
terraform apply -auto-approve
```

На этом шаге создаётся S3-бакет для state и генерируется статический
ключ доступа. Сохраните `access_key` и `secret_key`:

```bash
terraform output access_key
terraform output secret_key
terraform output bucket_name
```

### Шаг 2. Настройка переменных

Создайте `infrastructure/terraform.tfvars`:

```hcl
folder_id                = "b1glfq89j9n7quk0cnf0"
cloud_id                 = "b1g5akar41n0hohkvoq7"
service_account_key_file = "/path/to/sa-key.json"
```

Создайте `infrastructure/backend.tfvars`:

```hcl
access_key = "YCAJ..."
secret_key = "..."
```

### Шаг 3. Применение инфраструктуры

```bash
cd infrastructure
terraform init -backend-config=backend.tfvars
terraform plan
terraform apply -auto-approve
```

### Шаг 4. Доступ к кластеру

```bash
CLUSTER_ID=$(terraform output -raw k8s_cluster_id)
yc managed-kubernetes cluster get-credentials --id "$CLUSTER_ID" --external --force
kubectl get nodes
```

## CI/CD

Все изменения применяются через GitHub Actions. Workflow
`.github/workflows/infrastructure.yml` запускается при push в main
в папке `infrastructure/` и выполняет `terraform plan` и `apply`.

### GitHub Secrets

Для работы workflow нужны:

| Secret | Назначение |
|--------|-----------|
| `YC_SERVICE_ACCOUNT_KEY_B64` | JSON-ключ SA в base64 |
| `YC_ACCESS_KEY` | Статический ключ S3 (Access Key) |
| `YC_SECRET_KEY` | Статический ключ S3 (Secret Key) |
| `YC_CLOUD_ID` | ID облака |
| `YC_FOLDER_ID` | ID папки |
| `TF_BUCKET_NAME` | Имя S3-бакета для state |
| `K8S_SA_NAME` | Имя сервисного аккаунта |

### Кэширование

В workflow настроено кэширование Terraform-провайдеров и YC CLI.
Это ускоряет повторные запуски в 2–3 раза.

## Выводы

После применения доступны:

```bash
terraform output vpc_id
terraform output k8s_cluster_id
terraform output k8s_cluster_external_endpoint
terraform output worker_internal_ips
terraform output container_registry_url
terraform output bastion_public_ip
```

## Удаление

```bash
cd infrastructure
terraform destroy -auto-approve

cd ../backend
terraform destroy -auto-approve
```

## Особенности

- **Модульная архитектура.** Каждый компонент — отдельный модуль
  со своим интерфейсом. Модули переиспользуемы.
- **S3 backend с версионированием.** Позволяет откатиться к любой
  версии state.
- **Минимально необходимые права.** Сервисный аккаунт получает
  только те роли, которые действительно нужны.
- **Никакого хардкода.** Все параметры через переменные и Secrets.

## Документация

Полная пояснительная записка доступна по адресу:
[https://app.dubrovins.ru/docs.html](https://app.dubrovins.ru/docs.html)

## Лицензия

Проект создан в рамках дипломной работы курса
«DevOps для опытных инженеров» в Netology.