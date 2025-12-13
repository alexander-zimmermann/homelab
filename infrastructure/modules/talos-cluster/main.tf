###############################################################################
## Provider packages
###############################################################################
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.0"
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
  talos_inline_manifests = []

  ## Default talos_machine_configuration values passed into templatefile() patches
  talos_baseline_defaults = {
    talos_version = var.talos_version
    dns_servers   = var.dns_servers
    ntp_servers   = var.ntp_servers
  }

  talos_controlplane_defaults = {
    inline_manifests = jsonencode(local.talos_inline_manifests)
  }

  talos_dataplane_defaults = {
    longhorn_disk_selector_match_json = jsonencode(var.longhorn_disk_selector_match)
    longhorn_mount_path               = var.longhorn_mount_path
    longhorn_filesystem               = var.longhorn_filesystem
    longhorn_volume_name              = trimprefix(var.longhorn_mount_path, "/var/mnt/")
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
    templatefile("${path.root}/talos/config/baseline.yaml.tpl", local.talos_baseline_defaults),
    templatefile("${path.root}/talos/config/controlplane.yaml.tpl", local.talos_controlplane_defaults)
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
    templatefile("${path.root}/talos/config/baseline.yaml.tpl", local.talos_baseline_defaults),
    templatefile("${path.root}/talos/config/dataplane.yaml.tpl", local.talos_dataplane_defaults)
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
## Retrieve Kubeconfig & Talos config files
###############################################################################
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
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
