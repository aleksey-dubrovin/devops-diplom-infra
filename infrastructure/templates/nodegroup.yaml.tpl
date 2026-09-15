# =============================================================================
# NodeGroup для подключения внешних узлов к Managed Kubernetes
# =============================================================================
# Файл сгенерирован автоматически из шаблона nodegroup.yaml.tpl.
# Не редактируйте вручную — изменения будут перезаписаны при следующем apply.
# =============================================================================
apiVersion: mks.yandex.cloud/v1alpha1
kind: NodeGroup
metadata:
  name: ${nodegroup_name}
  namespace: ${namespace}
spec:
  # Список IP-адресов внешних узлов (приватные IP в VPC кластера)
  ips:
%{ for ip in worker_ips ~}
    - ${ip}
%{ endfor ~}
  # Автоматическая установка компонентов K8s на узлы через SSH
  provisionBySsh:
    sshKeySecret:
      name: ${ssh_secret_name}
      namespace: ${namespace}