# =============================================================================
# Создание security groups с правилами ingress и egress
# =============================================================================
resource "yandex_vpc_security_group" "this" {
  for_each = var.security_groups

  name        = each.key
  description = each.value.description
  network_id  = var.network_id
  folder_id   = var.folder_id

  # Динамические блоки ingress
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      protocol          = ingress.value.protocol
      description       = ingress.value.description
      port              = ingress.value.port
      from_port         = ingress.value.from_port
      to_port           = ingress.value.to_port
      v4_cidr_blocks    = ingress.value.v4_cidr_blocks
      security_group_id = ingress.value.security_group_id
      predefined_target = ingress.value.predefined_target
    }
  }

  # Динамические блоки egress
  dynamic "egress" {
    for_each = each.value.egress
    content {
      protocol          = egress.value.protocol
      description       = egress.value.description
      port              = egress.value.port
      from_port         = egress.value.from_port
      to_port           = egress.value.to_port
      v4_cidr_blocks    = egress.value.v4_cidr_blocks
      security_group_id = egress.value.security_group_id
      predefined_target = egress.value.predefined_target
    }
  }
}