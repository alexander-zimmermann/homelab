###############################################################################
## Storage identity
###############################################################################
variable "storage_id" {
  description = "Identifier for the storage backend as it appears in Proxmox (e.g. 'pbs-primary')."
  type        = string

  validation {
    condition     = length(var.storage_id) > 0
    error_message = "storage_id must be a non-empty string."
  }
}

variable "server" {
  description = "Hostname or IP address of the Proxmox Backup Server."
  type        = string

  validation {
    condition     = length(var.server) > 0
    error_message = "server must be a non-empty string."
  }
}

variable "datastore" {
  description = "Name of the datastore on the PBS instance to expose to Proxmox."
  type        = string

  validation {
    condition     = length(var.datastore) > 0
    error_message = "datastore must be a non-empty string."
  }
}

variable "nodes" {
  description = <<EOT
    Set of Proxmox nodes where the storage is available. Leave null to make it available on all nodes.
  EOT
  type        = set(string)
  default     = null

  validation {
    condition     = var.nodes == null || length(var.nodes) > 0
    error_message = "nodes must be null (all nodes) or a non-empty set of node names."
  }
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

  validation {
    condition     = length(var.username) > 0
    error_message = "username must be a non-empty string."
  }
}

variable "realm" {
  description = <<EOT
    Authentication realm for the user. Common values include `pbs`, `pam`, or
    external realms like `ldap`. Defaults to `pbs`.
  EOT
  type        = string
  default     = "pbs"

  validation {
    condition     = length(var.realm) > 0
    error_message = "realm must be a non-empty string."
  }
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
