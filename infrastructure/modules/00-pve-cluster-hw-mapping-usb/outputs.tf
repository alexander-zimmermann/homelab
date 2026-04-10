output "name" {
  description = <<EOT
    Name of the USB hardware mapping. Use this value in fleet VM configurations
    to reference the mapping via the 'usb_devices.mapping' attribute.
  EOT
  value       = proxmox_hardware_mapping_usb.this.name
}
