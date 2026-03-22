###############################################################################
## Storage identity
###############################################################################
variable "storage_id" {
  description = "Identifier for the storage backend as it appears in Proxmox (e.g. 'pbs-primary')."
  type        = string
}

variable "server" {
  description = "Hostname or IP address of the Proxmox Backup Server."
  type        = string
}

variable "datastore" {
  description = "Name of the datastore on the PBS instance to expose to Proxmox."
  type        = string
}

variable "nodes" {
  description = <<EOT
    Set of Proxmox nodes where the storage is available. Leave null to make it available on all nodes.
  EOT
  type        = set(string)
  default     = null
}


###############################################################################
## PBS connection
###############################################################################
variable "username" {
  description = <<EOT
    Username used by Proxmox to authenticate against PBS, without the realm suffix.
    The realm will be appended automatically (e.g., `backup@pbs`).
  EOT
  type        = string
}

variable "realm" {
  description = <<EOT
    Authentication realm for the user. Common values include `pbs`, `pam`, or
    external realms like `ldap`. Defaults to `pbs`.
  EOT
  type        = string
  default     = "pbs"
}

variable "password" {
  description = "Password for the PBS user. Sensitive value."
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = <<EOT
    TLS certificate fingerprint of the PBS instance for certificate pinning. Optional when
    PBS uses a publicly-trusted ACME cert. Required if PBS uses a self-signed certificate.
  EOT
  type        = string
  sensitive   = true
  default     = null
}
