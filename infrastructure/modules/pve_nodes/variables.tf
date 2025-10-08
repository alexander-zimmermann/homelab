###############################################################################
## Basic settings
###############################################################################
variable "node" {
  description = <<EOT
    Name of the Proxmox node to configure. This should match the node name
    as defined in your Proxmox cluster (e.g., `pve`).
  EOT
  type        = string
}

variable "timezone" {
  description = <<EOT
    Time zone to set on the Proxmox node. This affects system time and logging.
    Defaults to `Europe/Berlin`.
  EOT
  type        = string
  default     = "Europe/Berlin"
}

variable "dns_servers" {
  description = <<EOT
    List of DNS servers to configure on the node. These will be used for
    name resolution. Defaults to Cloudflare's IPv4 and IPv6 DNS.
  EOT
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]
}

variable "dns_search_domain" {
  description = <<EOT
    DNS search domain to configure on the node. This is used to resolve
    short hostnames within a specific domain context.
  EOT
  type        = string
}


###############################################################################
## Set content type for local storage
###############################################################################
variable "ssh_hostname" {
  description = <<EOT
    Hostname or IP address of the Proxmox node used for SSH access.
    This must be reachable from the system executing the configuration.
  EOT
  type        = string
}

variable "ssh_username" {
  description = <<EOT
    SSH username with root privileges on the Proxmox node.
    Defaults to `root`.
  EOT
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = <<EOT
    PEM-encoded private key used for SSH authentication to the Proxmox node.
    This key must allow access to the specified user and host. Sensitive value.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_port" {
  description = <<EOT
    SSH port used to connect to the Proxmox node. Defaults to `22`.
  EOT
  type        = number
  default     = 22
}

variable "local_content_types" {
  description = <<EOT
    Set of content types to allow on the `local` storage of the Proxmox node.
    Valid values include: `iso`, `vztmpl`, `backup`, `snippets`, `images`,
    `rootdir`, and `import`. These determine what types of files can be stored
    and used on the local volume.
  EOT
  type        = set(string)
  default     = ["iso", "vztmpl", "backup", ]

  validation {
    condition = length(
      setsubtract(
        var.local_content_types,
        toset(["iso", "vztmpl", "backup", "snippets", "images", "rootdir", "import"])
      )
    ) == 0
    error_message = "local_content_types must be a subset of: iso, vztmpl, backup, snippets, images, rootdir, import."
  }
}
