output "bond_setup_output" {
  description = <<EOT
    Log output from the `setup_bond.sh` script, which sets up network bonding
    on the Proxmox node. This output may include information about the bond
    interfaces created, their configurations, and any errors encountered during
    setup. Marked as sensitive to avoid exposing internal system details.
  EOT
  value       = var.create_bond ? try(data.external.bond_setup_output[0].result.output, "No log output available.") : "Bond creation not enabled"
  sensitive   = true
}

output "vlans" {
  description = <<EOT
    Map of created VLAN interface resource identifiers. Each entry maps the
    VLAN configuration key to its corresponding Proxmox resource ID. These
    IDs can be used to reference VLAN interfaces in other modules or for
    resource management operations.
  EOT
  value = {
    for k, v in proxmox_virtual_environment_network_linux_vlan.vlans :
    k => v.id
  }
}

output "bridges" {
  description = <<EOT
    Map of created bridge interface resource identifiers. Each entry maps the
    bridge configuration key to its corresponding Proxmox resource ID. These
    IDs can be used to reference bridge interfaces in VM network configurations
    or other modules that require bridge resource identifiers.
  EOT
  value = {
    for k, b in proxmox_virtual_environment_network_linux_bridge.bridges :
    k => b.id
  }
}
