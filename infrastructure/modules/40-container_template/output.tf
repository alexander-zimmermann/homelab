output "template_id" {
  description = <<EOT
    ID of the Proxmox LXC template created by this module. This identifier can be
    used to reference the template in other modules or provisioning workflows.
    It corresponds to the VM ID assigned by Proxmox during template creation.
  EOT
  value       = proxmox_virtual_environment_container.lxc_template.id
}

output "lxc_id" {
  description = "Numeric LXC ID assigned to the container"
  value       = proxmox_virtual_environment_container.lxc_template.vm_id
}

output "node" {
  description = "Proxmox node name where the template lives"
  value       = proxmox_virtual_environment_container.lxc_template.node_name
}
