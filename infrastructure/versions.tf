terraform {
  required_version = "1.14.4" # OpenTofu

  required_providers {
    proxmox = {
      ## https://search.opentofu.org/provider/bpg/proxmox/latest
      source  = "bpg/proxmox"
      version = "0.95.0"
    }
    external = {
      ## https://search.opentofu.org/provider/hashicorp/external/latest
      source  = "hashicorp/external"
      version = "=2.3.5"
    }
    local = {
      ## https://search.opentofu.org/provider/hashicorp/local/latest
      source  = "hashicorp/local"
      version = "2.7.0"
    }
    random = {
      ## https://search.opentofu.org/provider/hashicorp/random/latest
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    tls = {
      ## https://search.opentofu.org/provider/hashicorp/tls/latest
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
  }
}
