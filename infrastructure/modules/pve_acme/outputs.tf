output "acme_account_name" {
  description = <<EOT
    Name of the ACME account registered on the Proxmox node. This is used for
    certificate issuance and management via the ACME protocol.
  EOT
  value       = proxmox_virtual_environment_acme_account.this.name
}

output "dns_plugin_id" {
  description = <<EOT
    Identifier of the ACME DNS plugin used for DNS-01 challenge validation.
    Typically corresponds to the plugin type (e.g., `cloudflare`).
  EOT
  value       = proxmox_virtual_environment_acme_dns_plugin.this.plugin
}

output "dns_api_id" {
  description = <<EOT
    Short identifier for the DNS API provider used by the ACME plugin.
    For example, `cf` for Cloudflare.
  EOT
  value       = proxmox_virtual_environment_acme_dns_plugin.this.api
}


output "acme_order_output" {
  description = <<EOT
    Log output from the `acme_order.sh` script, which handles the ACME certificate
    request and installation process. This output may include challenge status,
    validation results, and any errors or success messages encountered during
    certificate issuance. Marked as sensitive to avoid exposing internal or
    potentially confidential information.
  EOT
  value       = try(data.external.acme_order_output.result.output, "No log output available.")
  sensitive   = true
}
