###############################################################################
## PVE API connection & auth
###############################################################################
variable "pve_token_id" {
  description = <<EOT
    Identifier of the Proxmox API token used for authentication. Must follow
    the format `username!tokenname`, where `username` includes the realm (e.g.,
    `admint@pam!mytoken`).
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^!]+![^!]+$", var.pve_token_id))
    error_message = "pve_token_id must follow the format 'username!tokenname'."
  }
}

variable "pve_token_secret" {
  description = <<EOT
    Secret value of the Proxmox API token. This is used together with `pve_token_id`
    to authenticate API requests. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "pve_password" {
  description = <<EOT
    Password for API authentication when not using an API token. Required for
    operations that require full user privileges. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}


###############################################################################
## PVE user management
###############################################################################
variable "pve_user_passwords" {
  description = "Map of username => password for PVE users defined in manifest/10-pve.yaml."
  type        = map(string)
  sensitive   = true
}


###############################################################################
## PVE certificate management
###############################################################################
variable "cf_token" {
  description = <<EOT
    Cloudflare API token used for DNS management. This is required for DNS-01
    challenge validation when using Cloudflare. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "cf_zone_id" {
  description = <<EOT
    Cloudflare Zone ID for the domain being validated. This identifies the DNS
    zone where challenge records will be created.
  EOT
  type        = string
  default     = null
}

variable "cf_account_id" {
  description = <<EOT
    Cloudflare Account ID. Optional and only required for certain API operations.
  EOT
  type        = string
  default     = null
}


###############################################################################
##  VM cloud-init configuration
###############################################################################
variable "ci_secrets" {
  description = "A map of secrets used for cloud-init injection (e.g., Lego tokens)."
  type        = map(map(string))
  sensitive   = true
  default     = {}
}
