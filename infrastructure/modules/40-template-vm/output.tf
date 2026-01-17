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

output "ci_user_data" {
  description = "Cloud-init user-data file ID used by this template"
  value       = var.ci_user_data
}

output "ci_vendor_data" {
  description = "Cloud-init vendor-data file ID used by this template"
  value       = var.ci_vendor_data
}

output "ci_network_data" {
  description = "Cloud-init network-data file ID used by this template"
  value       = var.ci_network_data
}

output "ci_meta_data" {
  description = "Cloud-init meta-data file ID used by this template"
  value       = var.ci_meta_data
}
