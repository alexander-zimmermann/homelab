###############################################################################
## Proxmox provider
###############################################################################

## Default provider: non-root auth via API token + SSH user/key
provider "proxmox" {
  api_token = "${var.pve_token_id}=${var.pve_token_secret}"
  endpoint  = local.pve_connection.api_url
  insecure  = local.pve_connection.insecure

  ## unified SSH user/key + per-node addresses
  ssh {
    agent       = local.pve_ssh.agent
    username    = local.pve_ssh.username
    private_key = file(pathexpand(local.pve_ssh.private_key_path))

    dynamic "node" {
      for_each = local.pve_nodes

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
  endpoint = local.pve_connection.api_url
  insecure = local.pve_connection.insecure
  username = local.pve_connection.username
  password = var.pve_password
}


###############################################################################
## Talos provider
###############################################################################
provider "talos" {}
