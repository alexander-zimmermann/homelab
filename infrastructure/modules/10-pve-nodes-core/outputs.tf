
output "local_content_type_output" {
  description = <<EOT
    Log output from the `local_content_types.sh` script, which sets the content
    types on the Proxmox node's local storage. This output may include supported
    formats such as `iso`, `vztmpl`, or others, and is useful for debugging or
    verifying storage configuration. Marked as sensitive to avoid exposing
    internal system details.
  EOT
  value       = try(data.external.local_content_type_output.result.output, "No log output available.")
  sensitive   = true
}
