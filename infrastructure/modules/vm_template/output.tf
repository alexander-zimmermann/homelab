output "template_id" {
  description = <<EOT
    ID of the Proxmox VM template created by this module. This identifier can be
    used to reference the template in other modules or provisioning workflows.
    It corresponds to the VM ID assigned by Proxmox during template creation.
  EOT
  value       = proxmox_virtual_environment_vm.vm_template.id
}

output "vmid" {
  description = "Numeric VM ID assigned to the template"
  value       = proxmox_virtual_environment_vm.vm_template.vm_id
}

output "node" {
  description = "Proxmox node name where the template lives"
  value       = proxmox_virtual_environment_vm.vm_template.node_name
}
