###############################################################################
## Mapping identity
###############################################################################
variable "name" {
  description = "Name of the USB hardware mapping as it appears in Proxmox."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "comment" {
  description = "Optional description for this USB hardware mapping."
  type        = string
  default     = null
}


###############################################################################
## Device map
###############################################################################
variable "map" {
  description = <<EOT
    List of USB device entries for this hardware mapping. Each entry associates
    a physical USB device (identified by vendor:product ID) with a Proxmox node.

      - id      : USB device identifier in 'vendorid:productid' format (e.g., "051d:0002").
      - node    : Proxmox node name where the device is physically connected.
      - comment : Optional device-specific note.
      - path    : Optional USB port path (e.g., "1-8.2") as alternative to ID-based matching.
  EOT
  type = list(object({
    id      = string
    node    = string
    comment = optional(string, null)
    path    = optional(string, null)
  }))

  validation {
    condition     = length(var.map) > 0
    error_message = "At least one device entry is required."
  }
}
