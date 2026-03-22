output "id" {
  description = "Identifier of the registered storage backend in Proxmox."
  value       = proxmox_virtual_environment_storage_pbs.this.id
}

output "pbs_ready_output" {
  description = <<EOT
    Log output from the PBS readiness polling script, which waits until the PBS
    API is reachable and the configured datastore is available. Marked as sensitive
    to avoid exposing credentials or internal system details.
  EOT
  value       = try(data.external.pbs_ready_output.result.output, "No log output available.")
  sensitive   = true
}
