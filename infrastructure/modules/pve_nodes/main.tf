###############################################################################
## Provider packages
###############################################################################
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.0"
    }
  }
}


###############################################################################
## Basic settings
###############################################################################
resource "proxmox_virtual_environment_time" "this" {
  node_name = var.node
  time_zone = var.timezone
}

resource "proxmox_virtual_environment_dns" "this" {
  node_name = var.node
  domain    = var.dns_search_domain
  servers   = var.dns_servers
}


###############################################################################
## APT repositories
###############################################################################
## Enable no subscription repository
resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription" {
  node   = var.node
  handle = "no-subscription"
}

resource "proxmox_virtual_environment_apt_repository" "enable_no_subscription" {
  enabled   = true
  node      = proxmox_virtual_environment_apt_standard_repository.no_subscription.node
  file_path = proxmox_virtual_environment_apt_standard_repository.no_subscription.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.no_subscription.index
}


## Disable enterprise repository
data "proxmox_virtual_environment_apt_standard_repository" "enterprise" {
  handle = "enterprise"
  node   = var.node
}

resource "proxmox_virtual_environment_apt_repository" "disable_enterprise" {
  node      = data.proxmox_virtual_environment_apt_standard_repository.enterprise.node
  file_path = data.proxmox_virtual_environment_apt_standard_repository.enterprise.file_path
  index     = data.proxmox_virtual_environment_apt_standard_repository.enterprise.index
  enabled   = false
}

## Disable ceph repository
data "proxmox_virtual_environment_apt_standard_repository" "ceph" {
  handle = "ceph-squid-enterprise"
  node   = var.node
}

resource "proxmox_virtual_environment_apt_repository" "disable_ceph" {
  node      = data.proxmox_virtual_environment_apt_standard_repository.ceph.node
  file_path = data.proxmox_virtual_environment_apt_standard_repository.ceph.file_path
  index     = data.proxmox_virtual_environment_apt_standard_repository.ceph.index
  enabled   = false
}


###############################################################################
## Local storage content types
###############################################################################
locals {
  content_types = join(",", sort(tolist(var.local_content_types)))
  script_path   = "/tmp/local_content_types.sh"
  log_output    = "/tmp/local_content_types.log"

  local_content_types_script = <<-BASH
    #!/usr/bin/env bash
    set -euo pipefail

    # Send everything to the log file
    exec > ${local.log_output} 2>&1

    # Log every command executed, with timestamp and source info
    trap 'printf "+ [%(%F %T)T] %s:%d: %s\n" -1 "$(basename -- "$BASH_SOURCE")" "$LINENO" "$BASH_COMMAND" >&2' DEBUG

    sudo /usr/sbin/pvesm set local --content ${local.content_types}
  BASH
}

resource "null_resource" "local_content_types" {
  ## Re-execute if any attribute changes
  triggers = {
    ## only re‑runs when the membership changes (not the order)
    content_types = local.content_types
  }

  connection {
    type        = "ssh"
    host        = var.ssh_hostname
    user        = var.ssh_username
    port        = var.ssh_port
    private_key = file(pathexpand(var.ssh_private_key))
    timeout     = "60s"
  }

  provisioner "file" {
    content     = local.local_content_types_script
    destination = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.script_path}",
      "/usr/bin/env bash ${local.script_path}"
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key} -P ${var.ssh_port} ${var.ssh_username}@${var.ssh_hostname}:${local.log_output} ${local.log_output}"
  }
}

data "external" "local_content_type_output" {
  depends_on = [null_resource.local_content_types]
  program    = ["bash", "-c", "cat ${local.log_output}| jq -R -s '{output: .}'"]
}
