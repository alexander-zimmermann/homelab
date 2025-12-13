# Talos baseline configuration for all nodes
# https://www.talos.dev/v1.11/reference/configuration/v1alpha1-config/
---
version: v1alpha1
debug: false

machine:
  # Installation configuration (important for upgrades and node replacements)
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:${talos_version}
    wipe: false

  # Disk encryption with node-specific keys
  systemDiskEncryption:
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
    state:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0

  # Kernel modules
  kernel:
    modules:
      - name: zfs

  # Network sysctls for modern Cilium eBPF mode
  sysctls:
    net.ipv4.ip_forward: "1"
    net.ipv6.conf.all.forwarding: "1"

  # Kubelet configuration
  kubelet:
    extraConfig:
      serverTLSBootstrap: true
    extraArgs:
      rotate-server-certificates: "true"

  # Network configuration
  network:
    nameservers:
%{ for ns in dns_servers ~}
      - ${ns}
%{ endfor ~}

  # Time synchronization
  time:
    servers:
%{ for s in ntp_servers ~}
      - ${s}
%{ endfor ~}

  # CRI metrics endpoint for Prometheus
  files:
    - path: /var/cri/conf.d/metrics.toml
      op: create
      content: |
        [metrics]
        address = "0.0.0.0:11234"

  # Talos features
  features:
    # KubePrism for HA API server access
    kubePrism:
      enabled: true
      port: 7445

    # Host DNS forwarding (Talos 1.8+)
    hostDNS:
      enabled: true
      forwardKubeDNSToHost: true

# Cluster configuration
cluster:
  network:
    # No CNI - Cilium will be deployed manually
    cni:
      name: none

  # Disable kube-proxy (Cilium replaces it in eBPF mode)
  proxy:
    disabled: true
