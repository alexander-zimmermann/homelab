# Talos control plane specific configuration
# https://www.talos.dev/v1.11/reference/configuration/v1alpha1-config/
---
version: v1alpha1
debug: false

machine:
  features:
    # Kubernetes Talos API Access (required for Talos CCM)
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system

cluster:
  # Bootstrap only: install the CSR approver early enough to break the serverTLSBootstrap
  # chicken-and-egg (kubelet serving CSRs -> diagnostics -> health gate).
  #
  # GitOps/ArgoCD will later take over managing this component (same namespace/name),
  # so keep this minimal and pinned.
  inlineManifests: ${inline_manifests}
