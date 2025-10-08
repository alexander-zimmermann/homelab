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
    The container hostname. Must be alphanumeric and may include dashes (`-`)
    and underscores (`_`). Underscores will be converted to dashes for DNS-compliant
    If not set, defaults to the Proxmox naming convention
    (e.g., `Copy-of-CT-<template_name>`).
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.name == null ? true : can(regex("^[a-zA-Z0-9_-]+$", var.name))
    error_message = "Container name must be null or an alphanumeric string (may contain dashes and underscores)."
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
## Template and cloning variables
###############################################################################
variable "datastore" { #####
  description = <<EOT
    Datastore / storage ID for container root filesystem volume. This datastore
    must have vztmpl enabled. Defaults to `local-lvm`.
  EOT
  type        = string
  default     = "local-lvm"
}

variable "template_node" {
  description = <<EOT
    Name of Proxmox node where the template resides. This should match the node
    name as defined in your Proxmox cluster (e.g., `pve`).
  EOT
  type        = string
  default     = null
}

variable "template_id" {
  description = <<EOT
     Numeric identifier of the Proxmox VM template to clone from. This should
    reference an existing VM template on the specified `template_node` and must
    match the `template_id` output from the `pve_vm_template` module. Required
    for creating a clone.
  EOT
  type        = number
}


###############################################################################
## CPU and memory variables
###############################################################################
variable "override_cpu" {
  description = <<EOT
    Whether to override the CPU configuration inherited from the template.
    If `true`, the `vcpu` and `vcpu_type` values will be applied to the clone.
    If `false`, the clone will retain the CPU settings from the template.
  EOT
  type        = bool
  default     = false
}

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

variable "override_memory" {
  description = <<EOT
    Whether to override the memory configuration inherited from the template.
    If `true`, the `memory` (and optionally `memory_floating`) values will be
    applied to the clone. If `false`, the clone will retain the memory settings
    from the template.
  EOT
  type        = bool
  default     = false
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
## Disk variables
###############################################################################
variable "mountpoint" {
  description = <<EOT
    A list of additional mountpoint configurations for the container. Each
    mountpoint allows you to attach additional storage volumes to the container
    beyond the root filesystem. Each object supports:

      - mp_volume: Storage volume identifier (e.g., `local-lvm:vm-100-disk-1`).
        If null, a new volume will be created automatically.
      - mp_size: Size of the volume in GiB. Required when creating new volumes.
      - mp_path: Mount path inside the container (e.g., `/mnt/data`).
      - mp_backup: Include this mountpoint in backups (default: false).
      - mp_read_only: Mount the volume as read-only (default: false).

    Use this variable to add persistent storage for data, logs, or application
    files that should persist beyond the container lifecycle or be shared
    between containers.
  EOT

  type = list(object({
    mp_volume    = optional(string, null)
    mp_size      = optional(number, null)
    mp_path      = optional(string, null)
    mp_backup    = optional(bool, false)
    mp_read_only = optional(bool, false)
  }))

  default = []

  validation {
    condition = var.mountpoint == null || alltrue([
      for mp in var.mountpoint : (
        mp.mp_path != null &&
        can(regex("^/[^\\s]*$", mp.mp_path)) &&
        (mp.mp_volume != null || mp.mp_size != null) &&
        (mp.mp_size == null || mp.mp_size > 0)
      )
    ])
    error_message = <<EOM
      Each mountpoint must meet these rules:
      - mp_path must be provided and be an absolute path starting with '/'
      - Either mp_volume (existing volume) or mp_size (new volume size in GiB) must be specified
      - mp_size, if provided, must be greater than 0
    EOM
  }
}


###############################################################################
## Network variables
###############################################################################
variable "network_interfaces" {
  description = <<EOT
    A list of additional network interface configurations to attach to the container.
    These NICs are provisioned in addition to the primary NIC created in the
    template. Each object supports:

      - vnic_name   : Network adapter name. Defaults to `eth0`.
      - vnic_bridge : Bridge to attach the adapter to (default: `vmbr0`).
      - vlan_tag    : Optional VLAN tag for the adapter (null means no VLAN).
      - mac_address : Static MAC address for consistent DHCP IP assignment.
                      If null, a MAC is auto-generated using the format:
                      "02:02:XX:XX:XX:YY" where XX:XX:XX is the Container_ID (3 bytes)
                      and YY is the interface index (0, 1, 2, ...).

    Use this variable to add extra network interfaces for management, storage,
    or application needs beyond the base NIC provided by the template.
  EOT

  type = list(object({
    vnic_name   = optional(string, "eth0")
    vnic_bridge = optional(string, "vmbr0")
    vlan_tag    = optional(number, null)
    mac_address = optional(string, null)
  }))

  default = [{
    vnic_name   = "eth0"
    vnic_bridge = "vmbr0"
    vlan_tag    = null
    mac_address = null
  }]

  validation {
    condition = alltrue([
      for nic in var.network_interfaces : (
        length(trimspace(nic.vnic_name)) > 0 &&
        length(trimspace(nic.vnic_bridge)) > 0 &&
        (nic.vlan_tag == null || (nic.vlan_tag >= 1 && nic.vlan_tag <= 4094)) &&
        (nic.mac_address == null || can(regex("^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", nic.mac_address)))
      )
    ])
    error_message = <<EOM
      Each network interface must meet these rules:
      - vnic_name must be a non-empty string
      - vnic_bridge must be a non-empty string
      - vlan_tag must be null or an integer between 1 and 4094
      - mac_address must be null or a valid MAC address format (xx:xx:xx:xx:xx:xx)
    EOM
  }
}


###############################################################################
## Initialization variables
###############################################################################
variable "override_dns" {
  description = "Whether to override DNS settings in the container initialization."
  type        = bool
  default     = false
}

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

variable "ipv4" {
  description = <<EOT
    A list of IPv4 network configurations for the container. Each configuration
    defines how the container obtains its IPv4 address and routing information.
    Each object supports:

      - ipv4_address: IPv4 address configuration. Can be "dhcp" for automatic
        assignment, or a static IP in CIDR notation (e.g., "192.168.1.100/24").
        Defaults to "dhcp".
      - ipv4_gateway: IPv4 gateway address for static configurations. Only required
        when using static IP addresses. Must be omitted when "dhcp" is used.

    Use this variable to configure network addressing for the container. For most
    use cases, the default DHCP configuration is sufficient. Use static IPs for
    servers that need predictable addresses or when DHCP is not available.
  EOT

  type = list(object({
    ipv4_address = optional(string, "dhcp")
    ipv4_gateway = optional(string, null)
  }))

  default = [{
    ipv4_address = "dhcp"
    ipv4_gateway = null
  }]

  validation {
    condition = alltrue([
      for ip in var.ipv4 : (
        (ip.ipv4_address == "dhcp" && ip.ipv4_gateway == null) ||
        (ip.ipv4_address != "dhcp" &&
          can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", ip.ipv4_address)) &&
          ip.ipv4_gateway != null &&
        can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip.ipv4_gateway)))
      )
    ])
    error_message = <<EOM
      Each IPv4 configuration must meet these rules:
      - ipv4_address must be either "dhcp" or a valid CIDR notation (e.g., "192.168.1.100/24")
      - ipv4_gateway must be null when using "dhcp"
      - ipv4_gateway must be provided and be a valid IPv4 address when using static IP addresses
    EOM
  }
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


###############################################################################
## Startup variables
###############################################################################
variable "start_on_boot" {
  description = "Start container on PVE boot."
  type        = bool
  default     = true
}

variable "start_on_create" {
  description = "Start container after creation."
  type        = bool
  default     = true
}

variable "start_order" {
  description = "Start order, e.g. `1`."
  type        = number
  default     = 1
}

variable "start_delay" {
  description = "Startup delay in seconds, e.g. `30`."
  type        = number
  default     = null
}

variable "shutdown_delay" {
  description = "Shutdown delay in seconds, e.g. `30`."
  type        = number
  default     = null
}
