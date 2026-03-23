###############################################################################
## Backup job identity
###############################################################################
variable "job_id" {
  description = "Unique identifier for the backup job as it appears in Proxmox (e.g. 'daily-backup')."
  type        = string

  validation {
    condition     = length(var.job_id) > 0
    error_message = "job_id must be a non-empty string."
  }
}

variable "schedule" {
  description = <<EOT
    Backup schedule in systemd calendar event format (e.g. '*-*-* 04:00' for daily at 4 AM).
    See: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_calendar_events
  EOT
  type        = string

  validation {
    condition     = length(var.schedule) > 0
    error_message = "schedule must be a non-empty string."
  }
}


###############################################################################
## Backup target
###############################################################################
variable "storage" {
  description = "Storage ID where backups will be stored. Must reference a PBS storage configured in Proxmox."
  type        = string

  validation {
    condition     = length(var.storage) > 0
    error_message = "storage must be a non-empty string."
  }
}

variable "vmids" {
  description = "List of VM/container IDs to include in the backup job. Must contain at least one ID."
  type        = list(number)

  validation {
    condition     = length(var.vmids) > 0
    error_message = "vmids must contain at least one VM/container ID."
  }

  validation {
    condition     = alltrue([for id in var.vmids : id > 0])
    error_message = "All VM IDs must be positive integers."
  }
}


###############################################################################
## Backup options
###############################################################################
variable "mode" {
  description = <<EOT
    Backup mode. One of:
      - snapshot: Live backup without downtime (requires QEMU guest agent or freeze support).
      - suspend:  Suspend the VM during backup.
      - stop:     Shut down the VM before backup and restart afterwards.
    Defaults to `snapshot`.
  EOT
  type        = string
  default     = "snapshot"

  validation {
    condition     = contains(["snapshot", "suspend", "stop"], var.mode)
    error_message = "mode must be one of: snapshot, suspend, stop."
  }
}

variable "compress" {
  description = <<EOT
    Compression algorithm for backup data. One of:
      - 0 / 1: No compression / LZO (legacy aliases).
      - gzip:  Good compression ratio, slower.
      - lzo:   Fast compression, lower ratio.
      - zstd:  Best balance of speed and compression ratio (recommended).
    Defaults to `zstd`.
  EOT
  type        = string
  default     = "zstd"

  validation {
    condition     = contains(["0", "1", "gzip", "lzo", "zstd"], var.compress)
    error_message = "compress must be one of: 0, 1, gzip, lzo, zstd."
  }
}
