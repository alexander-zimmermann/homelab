# Talos data plane configuration
# https://www.talos.dev/v1.11/reference/configuration/v1alpha1-config/
---
version: v1alpha1
debug: false

machine:
  nodeLabels:
    node-role.kubernetes.io/data-plane: ""

  kubelet:
    extraMounts:
      - destination: ${longhorn_mount_path}
        type: bind
        source: ${longhorn_mount_path}
        options:
          - bind
          - rshared
          - rw

---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: ${longhorn_volume_name}
provisioning:
  diskSelector:
    match: ${longhorn_disk_selector_match_json}
  minSize: 10G
filesystem:
  type: ${longhorn_filesystem}
