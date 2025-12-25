output "kube_config" {
  description = "Raw kubeconfig (YAML) after Talos bootstrap; sensitive auth data."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "kube_client_config" {
  description = "Client kubeconfig for kubectl (may embed certs); keep private."
  value       = talos_cluster_kubeconfig.this.kubernetes_client_configuration
  sensitive   = true
}

output "talos_config" {
  description = "Talos CLI config with endpoints & secrets; sensitive tokens/keys."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}
