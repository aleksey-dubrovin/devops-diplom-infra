# =============================================================================
# Bastion-хост
# =============================================================================
resource "yandex_compute_instance" "bastion" {
  name        = var.bastion_config.name
  platform_id = var.bastion_config.platform_id
  folder_id   = var.folder_id
  zone        = var.bastion_zone

  resources {
    cores         = var.bastion_config.cores
    memory        = var.bastion_config.memory
    core_fraction = var.bastion_config.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.bastion_config.disk_size
    }
  }

  network_interface {
    subnet_id          = var.public_subnet_id
    nat                = true
    security_group_ids = [var.security_group_ids["sg-bastion"]]
  }

  metadata = {
    ssh-keys = "${var.bastion_config.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.bastion_config.preemptible
  }
}

# =============================================================================
# Worker-узлы
# =============================================================================
resource "yandex_compute_instance" "worker" {
  for_each = var.worker_config.zones

  name        = "${var.worker_config.name_prefix}-${each.key}"
  platform_id = var.worker_config.platform_id
  folder_id   = var.folder_id
  zone        = each.value

  resources {
    cores         = var.worker_config.cores
    memory        = var.worker_config.memory
    core_fraction = var.worker_config.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.worker_config.disk_size
    }
  }

  network_interface {
    subnet_id          = var.private_subnet_ids[each.value]
    nat                = false
    security_group_ids = [var.security_group_ids["sg-k8s-workers"]]
  }

  metadata = {
    ssh-keys = "${var.worker_config.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.worker_config.preemptible
  }
}