# =============================================================================
# NodeGroup для подключения внешних узлов к Managed Kubernetes
# =============================================================================
apiVersion: mks.yandex.cloud/v1alpha1
kind: NodeGroup
metadata:
  name: ${nodegroup_name}
  namespace: ${namespace}
spec:
  ips:
%{ for ip in worker_ips ~}
    - ${ip}
%{ endfor ~}
  provisionBySsh:
    sshKeySecret:
      name: ${ssh_secret_name}
      namespace: ${namespace}