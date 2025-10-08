
output "user_data_file_id" {
  description = <<EOT
    ID of the cloud-init user-data snippet file created on the Proxmox node.
    This file contains user account configuration such as SSH keys, username,
    and optional password settings.
  EOT
  value       = try(proxmox_virtual_environment_file.user_config[0].id, null)
}

output "user_data_file_name" {
  description = <<EOT
    Filename of the cloud-init user-data snippet stored on the Proxmox node.
    This name is used to identify the snippet in the datastore and associate it with VM templates.
  EOT
  value       = try(proxmox_virtual_environment_file.user_config[0].source_raw[0].file_name, null)
}

output "vendor_data_file_id" {
  description = <<EOT
    ID of the cloud-init vendor-data snippet file created on the Proxmox node.
    This file includes system-level provisioning instructions such as package
    installation and custom commands.
  EOT
  value       = try(proxmox_virtual_environment_file.vendor_config[0].id, null)
}

output "vendor_data_file_name" {
  description = <<EOT
    Filename of the cloud-init vendor-data snippet stored on the Proxmox node.
    This name is used to identify the snippet in the datastore and associate it with VM templates.
  EOT
  value       = try(proxmox_virtual_environment_file.vendor_config[0].source_raw[0].file_name, null)
}

output "network_data_file_id" {
  description = <<EOT
    ID of the cloud-init network configuration snippet file created on the Proxmox node.
    This file defines interface settings, IP addressing, DNS servers, and SLAAC support.
    It can be referenced when provisioning VMs with cloud-init integration.
  EOT
  value       = try(proxmox_virtual_environment_file.network_config[0].id, null)
}

output "network_config_file_name" {
  description = <<EOT
    Filename of the cloud-init network configuration snippet stored on the Proxmox node.
    This name is used to identify the snippet in the datastore and associate it with VM templates.
  EOT
  value       = try(proxmox_virtual_environment_file.network_config[0].source_raw[0].file_name, null)
}

output "meta_data_file_id" {
  description = <<EOT
    ID of the cloud-init meta-data snippet file created on the Proxmox node.
    This file sets basic system identity parameters such as the local hostname.
  EOT
  value       = try(proxmox_virtual_environment_file.meta_config[0].id, null)
}

output "meta_data_file_name" {
  description = <<EOT
    Filename of the cloud-init meta-data snippet stored on the Proxmox node.
    This name is used to identify the snippet in the datastore and associate it with VM templates.
  EOT
  value       = try(proxmox_virtual_environment_file.meta_config[0].source_raw[0].file_name, null)
}
