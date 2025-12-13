###############################################################################
## Cluster identity
###############################################################################
variable "cluster_name" {
  description = <<EOT
    Logical cluster name used to tag Talos machine configurations and generate
    kubeconfig filename. Should be DNS-safe (lowercase alphanumerics + hyphen).
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name)) && length(var.cluster_name) > 0
    error_message = "cluster_name must be a non-empty DNS-safe string (lowercase letters, digits, hyphens)."
  }
}


###############################################################################
## Talos/Kubernetes versions
###############################################################################
variable "talos_version" {
  description = <<EOT
    Talos OS version (Major.Minor.Patch) without leading 'v'. Must match a
    released version published by SideroLabs. Example: 1.9.6
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "talos_version must be in semantic version form: X.Y.Z (e.g. 1.9.6)."
  }
}

variable "kubernetes_version" {
  description = <<EOT
    Target Kubernetes version provisioned by Talos. If null Talos defaults are
    used. When set must be a semantic version X.Y.Z matching Talos compatibility.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.kubernetes_version == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be null OR a semantic version X.Y.Z."
  }
}


###############################################################################
## Node topology
###############################################################################
variable "cluster_head" {
  description = <<EOT
    Primary control-plane node endpoint (usually IPv4 address) used for
    cluster API bootstrap and kubeconfig generation. Must be present in
    control_plane list.
  EOT
  type        = string

  validation {
    condition     = contains(var.control_plane, var.cluster_head)
    error_message = "cluster_head must be one of the control_plane node addresses."
  }
}

variable "control_plane" {
  description = <<EOT
    List of control-plane node addresses (IP or hostname) Talos should treat
    as API endpoints. Must contain at least one item. Order defines bootstrap
    head selection (cluster_head must be in this list).
  EOT
  type        = list(string)

  validation {
    condition     = length(var.control_plane) > 0 && alltrue([for n in var.control_plane : length(trimspace(n)) > 0])
    error_message = "control_plane must contain at least one non-empty address string."
  }
}

variable "data_plane" {
  description = <<EOT
    List of worker node addresses (IP or hostname). May be empty. Each string
    must be non-empty when provided.
  EOT
  type        = list(string)

  validation {
    condition     = alltrue([for n in var.data_plane : length(trimspace(n)) > 0])
    error_message = "data_plane entries must be non-empty strings (empty list allowed)."
  }
}


###############################################################################
## Node networking & time
###############################################################################
variable "dns_servers" {
  description = "DNS resolvers configured inside Talos nodes (machine.network.nameservers)."
  type        = list(string)
}

variable "ntp_servers" {
  description = "NTP servers configured inside Talos nodes (machine.time.servers)."
  type        = list(string)
}


###############################################################################
## Dataplane storage (Longhorn)
###############################################################################
variable "longhorn_disk_selector_match" {
  description = <<EOT
    Optional CEL expression for Talos v1.11 user volume disk selection.
    This is used as UserVolumeConfig.provisioning.diskSelector.match.
    Examples:
      - !system_disk
      - disk.transport == "nvme"
      - disk.model.contains("Samsung")
  EOT
  type        = string
  default     = "!system_disk"

  validation {
    condition     = length(trimspace(var.longhorn_disk_selector_match)) > 0
    error_message = "longhorn_disk_selector_match must be a non-empty CEL expression string (e.g. !system_disk)."
  }
}

variable "longhorn_mount_path" {
  description = "Mount path for Longhorn data on worker nodes. For Talos v1.11 user volumes this must be /var/mnt/<name> (e.g. /var/mnt/longhorn)."
  type        = string
  default     = "/var/mnt/longhorn"

  validation {
    condition     = can(regex("^/var/mnt/[A-Za-z0-9-]{1,34}$", var.longhorn_mount_path))
    error_message = "longhorn_mount_path must be /var/mnt/<name> where <name> is 1-34 chars of letters/digits/hyphens (e.g. /var/mnt/longhorn)."
  }
}

variable "longhorn_filesystem" {
  description = "Filesystem to format the Longhorn disk with (e.g. ext4)."
  type        = string
  default     = "ext4"

  validation {
    condition     = contains(["ext4", "xfs"], var.longhorn_filesystem)
    error_message = "longhorn_filesystem must be one of: ext4, xfs."
  }
}
