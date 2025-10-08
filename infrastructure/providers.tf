###############################################################################
## Proxmox provider
###############################################################################

## Default provider: non-root auth via API token + SSH user/key
provider "proxmox" {
  api_token = "${var.pve_token_id}=${var.pve_token_secret}"
  endpoint  = var.pve_api_url
  insecure  = var.pve_insecure

  ## unified SSH user/key + per-node addresses
  ssh {
    agent       = var.pve_ssh_use_agent
    username    = var.pve_ssh_username
    private_key = file(pathexpand(var.pve_ssh_private_key))

    dynamic "node" {
      for_each = var.pve_nodes

      content {
        name    = node.key
        address = node.value.address
        port    = node.value.port
      }
    }
  }
}

## Root-only provider alias, used sparingly, e.g. ACME account
provider "proxmox" {
  alias    = "root"
  endpoint = var.pve_api_url
  insecure = var.pve_insecure
  username = var.pve_username
  password = var.pve_password
}


###############################################################################
## Talos provider
###############################################################################
provider "talos" {}
