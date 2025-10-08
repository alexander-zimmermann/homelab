###############################################################################
## General LXC variables
###############################################################################
variable "node" {
  description = <<EOT
    Name of the Proxmox node on which the LXC template will be created. Must
    match an existing node name in your Proxmox cluster (e.g., `pve`).
  EOT
  type        = string
}

variable "name" {
  description = <<EOT
    Name of the LXC template. Must be alphanumeric and may include dashes (`-`)
    and underscores (`_`). Underscores will be converted to dashes for DNS-compliant
    hostname. If not set, defaults to the Proxmox naming convention (e.g., `CT <LXC_ID>`).
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.name == null || can(regex("^[a-zA-Z0-9_-]+$", var.name))
    error_message = "Template name must be null or an alphanumeric string (may contain dashes and underscores)."
  }
}

variable "lxc_id" {
  description = <<EOT
    Explicit numeric container ID. If null, Proxmox auto-assigns the next free
    ID. Set to enforce a stable and predictable numbering scheme.
  EOT
  type        = number
  default     = null

  validation {
    condition = var.lxc_id == null || (
      floor(var.lxc_id) == var.lxc_id && var.lxc_id >= 100 && var.lxc_id <= 999999999
    )
    error_message = "lxc_id must be null or an integer in the range 100..999999999."
  }
}

variable "unprivileged" {
  description = "Run container as unprivileged (recommended for isolation). Defaults to true."
  type        = bool
  default     = true
}

variable "description" {
  description = <<EOT
    Optional description for the LXC template. Useful for documentation and
    identifying the purpose of the template.
  EOT
  type        = string
  default     = null
}

variable "tags" {
  description = <<EOT
    List of UI tags for categorizing the template in Proxmox. Null to omit.
    Each tag must be a non-empty string.
  EOT
  type        = list(string)
  default     = null

  validation {
    condition     = var.tags == null || alltrue([for t in var.tags : length(trimspace(t)) > 0])
    error_message = "Each tag must be a non-empty string."
  }
}


###############################################################################
## CPU and memory variables
###############################################################################
variable "cores" {
  description = "Number of virtual CPU cores assigned to the container."
  type        = number
  default     = 1
}

variable "vcpu_architecture" {
  description = "Target CPU architecture reported inside the container."
  type        = string
  default     = "amd64"
  validation {
    condition     = contains(["amd64", "i386", "arm64", "armhf"], var.vcpu_architecture)
    error_message = "Invalid vcpu_architecture setting: ${var.vcpu_architecture}."
  }

}

variable "memory" {
  description = <<EOT
    RAM (MiB) allocated to the container. Default 512 MiB.
  EOT
  type        = number
  default     = 512
}

variable "memory_swap" {
  description = <<EOT
    Swap space (MiB) allocated to the container. Default 512 MiB.
  EOT
  type        = number
  default     = 512
}


###############################################################################
## Image variables
###############################################################################
variable "image_id" {
  description = <<EOT
    Identifier of the source image/template used to create this LXC root
    filesystem. Defaults to `unmanaged`.
  EOT
  type        = string
}

variable "os_type" {
  description = <<EOT
    OS type hint. Selects default LXC config snippets under
    `/usr/share/lxc/config/<ostype>.common.conf`. Use `unmanaged` to skip.
  EOT
  type        = string
  default     = "unmanaged"
  validation {
    condition = contains([
      "alpine", "archlinux", "centos", "debian", "devuan", "fedora",
    "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"], var.os_type)
    error_message = "Invalid OS type setting: ${var.os_type}."
  }
}


###############################################################################
## Disk variables
###############################################################################
variable "disk_datastore" {
  description = <<EOT
    Datastore / storage ID for container root filesystem volume.
    Defaults to `local-lvm`.
  EOT
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = <<EOT
    Root filesystem size (GiB). Adjust based on application requirements.
    Default is 4 GiB.
  EOT
  type        = number
  default     = 4
}


###############################################################################
## Network variables
###############################################################################
variable "vnic_name" {
  description = "Name for the primary network interface inside the container."
  type        = string
  default     = "eth0"
}

variable "vnic_bridge" {
  description = <<EOT
    Specifies the bridge to attach (e.g., `vmbr0`). Use an empty string for a
    NIC without a bridge (user-mode NAT 10.0.2.0/24), or null to omit the NIC entirely.
  EOT
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = <<EOT
    Optional VLAN tag (1..4094). If null, no VLAN tag is applied. VLAN
    tagging requires a NIC attached to a bridge (`vnic_bridge` to be set)
  EOT
  type        = number
  default     = null

  validation {
    condition = (
      var.vlan_tag == null ||
      (
        var.vlan_tag >= 1 &&
        var.vlan_tag <= 4094 &&
        length(trimspace(coalesce(var.vnic_bridge, ""))) > 0
      )
    )
    error_message = <<EOT
      vlan_tag must be null or an integer in the range 1..4094, and requires
      vnic_bridge to be set (non-empty).
    EOT
  }
}


###############################################################################
## Initialization variables
###############################################################################
variable "dns_servers" {
  description = <<EOT
    DNS resolver IP addresses (IPv4/IPv6). Defaults to Cloudflare 1.1.1.1 and
    2606:4700:4700::1111.
  EOT
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]

  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "dns_servers must contain at least one DNS server address."
  }
}

variable "dns_search_domain" {
  description = <<EOT
    A list of DNS search domains (e.g., `example.local`) used for short hostname
    expansion. An empty list means no search domains are applied.
  EOT
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = <<EOT
    Optional SSH public key for the root account. Set to null or an empty
    string to omit.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_key == null || length(trimspace(var.ssh_public_key)) > 0
    error_message = "ssh_public_key, if provided, must not be an empty string."
  }
}

variable "password" {
  description = "Optional password for the root account. Null or empty to omit."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.password == null || length(trimspace(var.password)) > 0
    error_message = "Password, if provided, must not be empty."
  }
}
