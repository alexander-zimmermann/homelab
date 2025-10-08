###############################################################################
## Role
###############################################################################
variable "create_role" {
  description = <<EOT
    Flag to determine whether a custom role should be created. If set to `true`,
    the specified privileges will be assigned to the role. If `false`, an existing
    role identified by `role_id` will be referenced.
  EOT
  type        = bool
  default     = false
}

variable "role_id" {
  description = <<EOT
    Identifier of the role to assign. This can be a built-in role (e.g., `PVEAdmin`,
    `PVEAuditor`) or a custom role name (e.g., `ops-monitoring`). Required whether
    creating or referencing a role.
  EOT
  type        = string
}

variable "role_privileges" {
  description = <<EOT
    List of privileges to assign to the role if `create_role` is `true`. Leave empty
    when referencing an existing role.
  EOT
  type        = list(string)
  default     = []
}


###############################################################################
## User
###############################################################################
variable "username" {
  description = <<EOT
    Username for the Proxmox user account, without the realm suffix. The realm
    will be appended automatically (e.g., `admin@pve`).
  EOT
  type        = string
}

variable "realm" {
  description = <<EOT
    Authentication realm for the user. Common values include `pve`, `pam`, or
    external realms like `ldap`. Defaults to `pve`.
  EOT
  type        = string
  default     = "pve"
}

variable "password" {
  description = <<EOT
    Password for the user account. Required for `pve` and `pam` realms unless
    using API tokens. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "enabled" {
  description = <<EOT
    Whether the user account is enabled. If set to `false`, the account will be
    disabled and cannot log in.
  EOT
  type        = bool
  default     = true
}

variable "first_name" {
  description = <<EOT
    Optional first name of the user. Used for display and identification purposes.
  EOT
  type        = string
  default     = null
}

variable "last_name" {
  description = <<EOT
    Optional last name of the user. Used for display and identification purposes.
  EOT
  type        = string
  default     = null
}

variable "email" {
  description = <<EOT
    Optional email address of the user. Used for notifications and contact.
  EOT
  type        = string
  default     = null
}

variable "comment" {
  description = <<EOT
    Free-form comment associated with the user account. Useful for documentation
    or administrative notes. Defaults to `Managed by OpenTofu`.
  EOT
  type        = string
  default     = "Managed by OpenTofu"
}


###############################################################################
## Token
###############################################################################
variable "create_token" {
  description = <<EOT
    Flag to determine whether an API token should be created for the user.
    If `true`, a token will be generated using the specified `token_name`.
  EOT
  type        = bool
  default     = false
}

variable "token_name" {
  description = <<EOT
    Identifier for the API token associated with the user. Required when
    `create_token` is `true`.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.create_token == false || length(var.token_name) > 0
    error_message = "If create_token = true, token_name must be a non-empty string."
  }
}

variable "privileges_separation" {
  description = <<EOT
    If `true`, restrict the API token's privileges using separate ACLs. If `false`,
    the token inherits the full privileges of the associated user.
  EOT
  type        = bool
  default     = false
}


###############################################################################
## ACL
###############################################################################
variable "path" {
  description = <<EOT
    ACL path within the Proxmox environment where permissions will be applied.
    Examples include `/` for global access or `/vms/1234` for VM-specific access.
  EOT
  type        = string
}

variable "propagate" {
  description = <<EOT
    Whether the ACL should propagate to child paths. If `true`, permissions will
    apply recursively to sub-resources.
  EOT
  type        = bool
  default     = true
}
