###############################################################################
## PVE node configuration
###############################################################################
output "local_content_type_output" {
  description = <<EOT
    Log output from the `local_content_types.sh` script for each Proxmox node.
    This output contains the detected or configured content types allowed on
    the `local` storage (e.g., `iso`, `vztmpl`, `snippets`). Useful for verifying
    storage capabilities across nodes. Marked as sensitive to avoid exposing
    internal system details.
  EOT
  value       = { for k, v in module.pve_nodes : k => v.local_content_type_output }
  sensitive   = true
}


###############################################################################
## PVE user management
###############################################################################
output "token_value" {
  description = <<EOT
    API token value for each managed user. This token is used for authenticating
    API requests to the Proxmox cluster. Only populated when a new token is created.
    Marked as sensitive to prevent exposure of credentials.
  EOT
  value       = { for k, v in module.pve_user_mgmt : k => try(v.token_value, null) }
  sensitive   = true
}


###############################################################################
## PVE certificate management
###############################################################################
output "acme_order_output" {
  description = <<EOT
    Log output from the `acme_order.sh` script, which includes DNS challenge
    validation, certificate request status, and installation results. Useful for
    debugging and auditing certificate provisioning. Marked as sensitive to avoid
    exposing internal details or domain information.
  EOT
  value       = module.pve_acme.acme_order_output
  sensitive   = true
}


###############################################################################
## PVE network configuration
###############################################################################
output "bond_output" {
  description = <<EOT
    Log output from the `setup_bond.sh` script, which configures network
    bonds on the Proxmox node. This output may include information about
    created bonds and any errors encountered during setup. Marked as
    sensitive to avoid exposing internal system details.
  EOT
  value       = { for k, v in module.pve-bond : k => v.bond_setup_output }
  sensitive   = true
}

output "vlan_output" {
  description = <<EOT
    Map of created VLAN interface resource identifiers. Each entry maps the
    VLAN configuration key to its corresponding Proxmox resource ID. These
    IDs can be used to reference VLAN interfaces in other modules or for
    resource management operations.
  EOT
  value       = { for k, v in module.pve-vlan : k => v.vlans }
  sensitive   = false
}

output "bridge_output" {
  description = <<EOT
    Map of created bridge interface resource identifiers. Each entry maps the
    bridge configuration key to its corresponding Proxmox resource ID. These
    IDs can be used to reference bridge interfaces in VM network configurations
    or other modules that require bridge resource identifiers.
  EOT
  value       = { for k, v in module.pve-bridge : k => v.bridges }
  sensitive   = false
}


###############################################################################
##  Virtual machine & container clones
###############################################################################
output "vms_id" {
  value = { for k, v in module.virtual_machines : k => v.id }
}

output "vms_ipv4" {
  value = { for k, v in module.virtual_machines : k => try(flatten(v.ipv4), []) }
}

output "vms_ipv6" {
  value = { for k, v in module.virtual_machines : k => try(flatten(v.ipv6), []) }
}

output "containers_id" {
  value = { for k, v in module.containers : k => v.id }
}

output "containers_ipv4" {
  value = { for k, v in module.containers : k => try(flatten(v.ipv4), []) }
}

output "containers_ipv6" {
  value = { for k, v in module.containers : k => try(flatten(v.ipv6), []) }
}


###############################################################################
## Talos cluster
###############################################################################
output "talos_control_plane_ids" {
  description = "Keys for generated Talos control plane VMs (e.g. talos_cp_*)."
  value       = local.control_plane_node_ids
}

output "talos_data_plane_ids" {
  description = "Keys for generated Talos worker VMs (e.g. talos_dp_*)."
  value       = local.data_plane_node_ids
}

output "talos_control_plane_ipv4" {
  description = "IPv4 addresses of Talos control plane nodes keyed by VM key."
  value       = { for k in local.control_plane_node_ids : k => try(module.virtual_machines[k].ipv4, []) }
}

output "talos_data_plane_ipv4" {
  description = "IPv4 addresses of Talos worker nodes keyed by VM key."
  value       = { for k in local.data_plane_node_ids : k => try(module.virtual_machines[k].ipv4, []) }
}
