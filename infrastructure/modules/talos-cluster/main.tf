###############################################################################
## Provider packages
###############################################################################
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.87.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.9.0, < 1.0.0"
    }
  }
}


###############################################################################
## Talos machine secrets
###############################################################################
resource "talos_machine_secrets" "this" {}


###############################################################################
## Talos client configuration
###############################################################################
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = var.control_plane
  nodes                = concat(var.control_plane, var.data_plane)
}


###############################################################################
## Talos machine configurations
###############################################################################
locals {
  ## Default talos_machine_configuration values
  talos_mc_defaults = {
    talos_version = var.talos_version
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_head}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    templatefile("${path.root}/talos/baseline.yaml.tpl", local.talos_mc_defaults)
  ]
}

data "talos_machine_configuration" "dataplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_head}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    templatefile("${path.root}/talos/baseline.yaml.tpl", local.talos_mc_defaults)
  ]
}

resource "talos_machine_configuration_apply" "cp" {
  count                       = length(var.control_plane)
  node                        = var.control_plane[count.index]
  endpoint                    = var.control_plane[count.index]
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  client_configuration        = talos_machine_secrets.this.client_configuration
}

resource "talos_machine_configuration_apply" "dp" {
  count                       = length(var.data_plane)
  node                        = var.data_plane[count.index]
  endpoint                    = var.data_plane[count.index]
  machine_configuration_input = data.talos_machine_configuration.dataplane.machine_configuration
  client_configuration        = talos_machine_secrets.this.client_configuration
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.cp,
    talos_machine_configuration_apply.dp
  ]

  node                 = var.cluster_head
  endpoint             = var.cluster_head
  client_configuration = talos_machine_secrets.this.client_configuration

  lifecycle {
    ignore_changes = all
  }
}


###############################################################################
## Wait for cluster ready before generating kubeconfig
###############################################################################
data "talos_cluster_health" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = var.control_plane
  worker_nodes         = var.data_plane
  endpoints            = data.talos_client_configuration.this.endpoints

  ## Wait up to 10 minutes for cluster to become healthy
  ## This allows time for all Kubernetes components to start
  timeouts = {
    read = "10m"
  }
}


###############################################################################
## Retrieve Kubeconfig (resource replaces deprecated data source)
###############################################################################
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [data.talos_cluster_health.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.cluster_head
  node                 = var.cluster_head
}

resource "local_file" "kubeconfig" {
  content              = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename             = "${path.root}/build/kubeconfig_${var.cluster_name}.yaml"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "talosconfig" {
  content              = data.talos_client_configuration.this.talos_config
  filename             = "${path.root}/build/talosconfig_${var.cluster_name}.yaml"
  file_permission      = "0600"
  directory_permission = "0700"
}
