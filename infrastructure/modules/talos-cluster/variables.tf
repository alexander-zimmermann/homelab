

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
