terraform {
  required_version = "= 1.11.1" # OpenTofu

  required_providers {
    proxmox = {
      ## https://search.opentofu.org/provider/bpg/proxmox/latest
      source  = "bpg/proxmox"
      version = "=0.89.0"
    }
    external = {
      ## https://search.opentofu.org/provider/hashicorp/external/latest
      source  = "hashicorp/external"
      version = "=2.3.5"
    }
    local = {
      ## https://search.opentofu.org/provider/hashicorp/local/latest
      source  = "hashicorp/local"
      version = "2.6.2"
    }
    random = {
      ## https://search.opentofu.org/provider/hashicorp/random/latest
      source  = "hashicorp/random"
      version = "=3.7.2"
    }
    tls = {
      ## https://search.opentofu.org/provider/hashicorp/tls/latest
      source  = "hashicorp/tls"
      version = "=4.1.0"
    }
  }
}
