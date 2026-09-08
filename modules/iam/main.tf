# Если create_sa = true – создаём новый аккаунт, иначе используем существующий по имени
resource "yandex_iam_service_account" "sa" {
  count       = var.create_sa ? 1 : 0
  name        = var.sa_name
  description = "Сервисный аккаунт для Terraform и управления инфраструктурой"
}

data "yandex_iam_service_account" "sa" {
  count = var.create_sa ? 0 : 1
  name  = var.sa_name
}

locals {
  sa_id = var.create_sa ? yandex_iam_service_account.sa[0].id : data.yandex_iam_service_account.sa[0].id
}

# Назначение ролей
resource "yandex_resourcemanager_folder_iam_member" "sa_roles" {
  for_each  = toset(var.roles)
  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${local.sa_id}"
}
