terraform {
  required_version = "= 1.10.6" # OpenTofu

  required_providers {
    proxmox = {
      ## https://search.opentofu.org/provider/bpg/proxmox/latest
      source  = "bpg/proxmox"
      version = "=0.87.0"
    }
    talos = {
      ## https://search.opentofu.org/provider/siderolabs/talos/latest
      source  = "siderolabs/talos"
      version = "=0.9.0"
    }
    external = {
      ## https://search.opentofu.org/provider/hashicorp/external/latest
      source  = "hashicorp/external"
      version = "=2.3.5"
    }
    local = {
      ## https://search.opentofu.org/provider/hashicorp/local/latest
      source  = "hashicorp/local"
      version = "=2.5.3"
    }
    null = {
      ## https://search.opentofu.org/provider/hashicorp/null/latest
      source  = "hashicorp/null"
      version = "=3.2.4"
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
