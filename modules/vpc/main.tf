# =============================================================================
# VPC (виртуальная частная сеть)
# =============================================================================
resource "yandex_vpc_network" "main" {
  name        = var.vpc_name
  description = "VPC для дипломного проекта"
  folder_id   = var.folder_id
}

# =============================================================================
# Публичные подсети (без NAT — для ВМ с публичным IP)
# =============================================================================
resource "yandex_vpc_subnet" "public" {
  for_each = var.public_subnet_cidrs

  name           = "public-${each.key}"
  description    = "Публичная подсеть в зоне ${each.key}"
  network_id     = yandex_vpc_network.main.id
  zone           = each.key
  v4_cidr_blocks = [each.value]
  folder_id      = var.folder_id
}

# =============================================================================
# Приватные подсети (с NAT через таблицу маршрутизации)
# =============================================================================
resource "yandex_vpc_subnet" "private" {
  for_each = var.private_subnet_cidrs

  name           = "private-${each.key}"
  description    = "Приватная подсеть для внешних узлов в зоне ${each.key}"
  network_id     = yandex_vpc_network.main.id
  zone           = each.key
  v4_cidr_blocks = [each.value]
  folder_id      = var.folder_id

  # Привязка таблицы маршрутизации для выхода в интернет через NAT
  route_table_id = var.enable_nat ? yandex_vpc_route_table.nat[0].id : null
}

# =============================================================================
# Управляющие подсети (для Managed K8s)
# =============================================================================
resource "yandex_vpc_subnet" "mgmt" {
  for_each = var.mgmt_subnet_cidrs

  name           = "mgmt-${each.key}"
  description    = "Управляющая подсеть для Managed K8s в зоне ${each.key}"
  network_id     = yandex_vpc_network.main.id
  zone           = each.key
  v4_cidr_blocks = [each.value]
  folder_id      = var.folder_id
}

# =============================================================================
# NAT-шлюз (только если enable_nat = true)
# =============================================================================
resource "yandex_vpc_gateway" "nat" {
  count = var.enable_nat ? 1 : 0

  name        = var.nat_gateway_name
  description = "NAT-шлюз для исходящего трафика из приватных подсетей"
  folder_id   = var.folder_id

  shared_egress_gateway {}
}

# =============================================================================
# Таблица маршрутизации для приватных подсетей через NAT
# =============================================================================
resource "yandex_vpc_route_table" "nat" {
  count = var.enable_nat ? 1 : 0

  name        = "private-nat-route-table"
  description = "Таблица маршрутизации для приватных подсетей через NAT"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.folder_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat[0].id
  }
}

# =============================================================================
# Приватный эндпоинт для Object Storage (S3)
# =============================================================================
resource "yandex_vpc_private_endpoint" "s3" {
  count = var.s3_private_endpoint.enable ? 1 : 0

  name        = var.s3_private_endpoint.name
  description = "Приватный эндпоинт для Object Storage"
  network_id  = yandex_vpc_network.main.id
  folder_id   = var.folder_id

  # Используем service_name для указания сервиса Object Storage
  service_name = "yandex.cloud.storage"

  # Включаем автоматическое создание приватной DNS-записи
  dns_options {
    private_dns_records_enabled = true
  }

  # Размещаем эндпоинт в управляющей подсети указанной зоны
  endpoint_address {
    subnet_id = yandex_vpc_subnet.mgmt[var.s3_private_endpoint.zone].id
  }
}