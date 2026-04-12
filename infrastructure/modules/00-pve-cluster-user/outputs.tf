output "user_id" {
  description = <<EOT
    Full user ID including the authentication realm (e.g., `admin@pve`). This
    identifier is used to manage permissions, tokens, and access control within
    the Proxmox environment.
  EOT
  value       = proxmox_virtual_environment_user.this.user_id
}

output "role_id" {
  description = <<EOT
    Identifier of the role used in the ACL assignment. This may refer to a
    built-in role (e.g., `PVEAdmin`) or a custom role created during provisioning.
    Returns `null` if no role was created.
  EOT
  value       = try(proxmox_virtual_environment_role.this[0].role_id, null)
}

output "token_id" {
  description = <<EOT
    Identifier of the API token associated with the user. This is used for
    programmatic access to the Proxmox API. Returns `null` if no token was created.
  EOT
  value       = try(proxmox_user_token.this[0].id, null)
}

output "token_value" {
  description = <<EOT
    API token secret (UUID portion only) used for authentication. The provider
    returns the full "id=secret" string, so this output extracts just the secret.
    Marked as sensitive to avoid accidental exposure.
  EOT
  value       = try(split("=", proxmox_user_token.this[0].value)[1], null)
  sensitive   = true
}

output "acl_id" {
  description = <<EOT
    Identifier of the ACL entry applied to the specified path. This includes
    the user, role, and propagation settings used to manage access control
    within the Proxmox environment.
  EOT
  value       = proxmox_acl.this.id
}
