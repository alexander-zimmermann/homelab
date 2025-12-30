###############################################################################
##  General variables for the module
###############################################################################
variable "node" {
  description = <<EOT
    Name of the Proxmox node where the cloud-init snippet will be created.
    This should match the node name as defined in your Proxmox cluster (e.g., `pve`).
  EOT
  type        = string
}

variable "datastore" {
  description = <<EOT
    ID of the datastore where the cloud-init snippet will be stored.
    This datastore must have snippets enabled. Defaults to `local`.
  EOT
  type        = string
  default     = "local"
}

variable "filename" {
  description = <<EOT
    Name of the cloud-init snippet file to be created. This should be unique
    per configuration and follow a consistent naming convention
    (e.g.,`vm01-user-config.yaml`).
  EOT
  type        = string

  validation {
    condition     = length(var.filename) > 0
    error_message = "filename must be a non-empty string."
  }
}


###############################################################################
##  User config
###############################################################################
variable "create_user_config" {
  description = <<EOT
    Flag to enable creation of a cloud-init user-data snippet. When true,
    user account settings will be applied to the VM. Defaults to `false`.
  EOT
  type        = bool
  default     = false
}

variable "users" {
  description = <<EOT
    List of user configurations to create. Each object represents a user
    with properties like username, password, ssh_keys, and groups.
  EOT
  type = list(object({
    username       = string
    ssh_public_key = optional(string, "")
    password       = optional(string, "")
    set_password   = optional(bool, false)
    groups         = optional(list(string), ["sudo"])
  }))
  default = []

  validation {
    condition     = alltrue([for u in var.users : (!u.set_password) || length(u.password) > 0])
    error_message = "Password must be provided for any user where set_password is true."
  }

  validation {
    condition     = alltrue([for u in var.users : length(u.ssh_public_key) > 0])
    error_message = "ssh_public_key must be set for all users."
  }
}


###############################################################################
##  Vendor config
###############################################################################
variable "create_vendor_config" {
  description = <<EOT
    Flag to enable creation of a cloud-init vendor-data snippet. When true,
    system-level provisioning such as package installation and command execution
    will be applied to the VM. Defaults to `false`.
  EOT
  type        = bool
  default     = false
}

variable "package_update" {
  description = <<EOT
    Whether to update the package index before installing packages.
    Defaults to true.
  EOT
  type        = bool
  default     = true
}

variable "package_upgrade" {
  description = <<EOT
    Whether to upgrade installed packages to their latest versions.
    Defaults to true.
  EOT
  type        = bool
  default     = true
}

variable "package_reboot_if_required" {
  description = <<EOT
    Whether to reboot the system if a package upgrade requires a reboot.
    Defaults to true.
  EOT
  type        = bool
  default     = true
}

variable "packages" {
  description = <<EOT
    List of additional packages to install during provisioning.
    If empty, only `qemu-guest-agent` will be installed.
  EOT
  type        = list(string)
  default     = []
}

variable "mounts" {
  description = <<EOT
    List of mount points to configure.
    Each item is a list: [ source, target, fs_type, options, dump, pass ]
  EOT
  type        = list(any)
  default     = []
}

variable "mount_default_fields" {
  description = <<EOT
    Default values for mount fields if not specified.
    List of 6 strings: [ source, target, fs_type, options, dump, pass ]
  EOT
  type        = list(string)
  default     = []
}

variable "bootcmd" {
  description = <<EOT
    List of shell commands to run early in the boot process (before networking).
    Useful for directory creation, disk formatting, etc.
  EOT
  type        = list(any)
  default     = []
}

variable "runcmd" {
  description = <<EOT
    List of shell commands to run during provisioning. These will be executed
    after enabling the `qemu-guest-agent`. Use an empty list to skip custom commands.
  EOT
  type        = list(any)
  default     = []
}

variable "snap" {
  description = <<EOT
    Custom Snap configuration (commands, assertions, etc.).
    Passed directly to cloud-init's `snap` module.
  EOT
  type        = any
  default     = {}
}

variable "write_files" {
  description = <<EOT
    List of files to write to the VM filesystem during cloud-init execution.
    Each item is an object containing path, content, permissions, owner, and encoding.
  EOT
  type = list(object({
    path          = string
    content       = optional(string)
    content_file  = optional(string)
    template_file = optional(string)
    secret_ref    = optional(string)
    vars          = optional(map(string))
    permissions   = optional(string, "0644")
    owner         = optional(string, "root:root")
    encoding      = optional(string, "text/plain")
    append        = optional(bool, false)
  }))
  default = []
}


###############################################################################
##  Network config
###############################################################################
variable "create_network_config" {
  description = <<EOT
    Flag to enable creation of a cloud-init network configuration snippet. When true,
    network settings such as IP address, gateway, DNS servers, and SLAAC will be
    applied to the VM during provisioning. Defaults to `false`.
  EOT
  type        = bool
  default     = false
}

variable "dhcp4" {
  description = <<EOT
    Enable DHCP for IPv4. Set to true to automatically assign an IPv4 address via DHCP.
  EOT
  type        = bool
  default     = true
}

variable "dhcp6" {
  description = <<EOT
    Enable DHCP for IPv6. Set to false when using SLAAC (Stateless Address
    Autoconfiguration). Cannot be true if `accept_ra` is also true.
  EOT
  type        = bool
  default     = false
}

variable "accept_ra" {
  description = <<EOT
    Enable IPv6 SLAAC via router advertisements. Set to true to allow automatic IPv6
    configuration without DHCPv6. Cannot be true if `dhcp6` is also true.
  EOT
  type        = bool
  default     = true

  validation {
    condition     = var.create_network_config == false || !(var.dhcp6 && var.accept_ra)
    error_message = <<EOT
      dhcp6 and accept_ra cannot both be true when create_network_config is true.
      Use either DHCPv6 or SLAAC, not both.
    EOT
  }
}

variable "ipv4_address" {
  description = <<EOT
    Static IPv4 address with CIDR notation (e.g., '192.168.1.100/24').
    Must not be set when `dhcp4` is enabled.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_network_config == false || var.dhcp4 == false || length(var.ipv4_address) == 0
    error_message = <<EOT
      ipv4_address must not be set when dhcp4 is true and create_network_config
      is true.
    EOT
  }
}

variable "ipv6_address" {
  description = <<EOT
    Static IPv6 address with CIDR notation (e.g., '2001:db8::1/64').
    Must not be set when `dhcp6` or `accept_ra` is enabled.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_network_config == false || (var.dhcp6 == false && var.accept_ra == false) || length(var.ipv6_address) == 0
    error_message = <<EOT
      ipv6_address must not be set when dhcp6 or accept_ra is true and
      create_network_config is true.
    EOT
  }
}

variable "gateway4" {
  description = <<EOT
    IPv4 gateway address. Required when `ipv4_address` is set and `create_network_config`
    is true. Leave empty when not using static IPv4 configuration.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_network_config == false || length(var.ipv4_address) == 0 || length(var.gateway4) > 0
    error_message = <<EOT
      gateway4 must be provided when ipv4_address is set and create_network_config is true.
    EOT
  }
}

variable "gateway6" {
  description = <<EOT
    IPv6 gateway address. Required when `ipv6_address` is set and `create_network_config`
    is true. Leave empty when not using static IPv6 configuration.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_network_config == false || length(var.ipv6_address) == 0 || length(var.gateway6) > 0
    error_message = <<EOT
      gateway6 must be provided when ipv6_address is set and create_network_config
      is true.
    EOT
  }
}

variable "dns_servers" {
  description = <<EOT
    List of DNS server IP addresses (IPv4 or IPv6) to configure for the VM.
    Only used when static IP addresses are configured. When using DHCP,
    DNS servers will be obtained from DHCP. Defaults to Cloudflare DNS
    servers: `1.1.1.1` and `2606:4700:4700::1111`.
  EOT
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]

  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "At least one DNS server must be provided."
  }
}

variable "dns_search_domain" {
  description = <<EOT
    DNS search domain to include in the cloud-init network configuration (e.g.,
    'example.local'). This helps resolve short hostnames within the domain context.
  EOT
  type        = list(string)
  default     = []
}


###############################################################################
##  Meta config
###############################################################################
variable "create_meta_config" {
  description = <<EOT
    Flag to enable creation of a cloud-init meta-data snippet. When true, basic
    system identity settings such as hostname will be applied. Defaults to `false`.
  EOT
  type        = bool
  default     = false
}

variable "hostname" {
  description = <<EOT
    Local hostname to assign to the VM. This will be written to `/etc/hostname`
    and used as the system identifier during boot. Required when
    `create_meta_config` is true.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_meta_config == false || length(var.hostname) > 0
    error_message = "hostname must be provided when create_meta_config is true."
  }
}
