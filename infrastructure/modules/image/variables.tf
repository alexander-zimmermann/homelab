variable "node" {
  description = <<EOT
    Name of the Proxmox node where the image will be downloaded.
    This should match the node name as defined in your Proxmox cluster (e.g., `pve`).
  EOT
}

variable "datastore" {
  description = <<EOT
    ID of the datastore where the VM or LXC image  will be stored.
    This datastore must have iso enabled. Defaults to `local`.
  EOT
  type        = string
  default     = "local"
}

variable "image_filename" {
  description = <<EOT
    Filename to use when saving the image on the Proxmox node. If set to `null`,
    the filename will be automatically extracted from the `image_url`.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.image_url == "" || var.image_filename != ""
    error_message = "image_filename must be provided or derivable from image_url."
  }
}

variable "image_url" {
  description = <<EOT
    URL from which the image will be downloaded. This must be a valid HTTP(S)
    endpoint pointing to an ISO or LXC template file.

    Can be empty ("") for manually uploaded images - in this case the module
    will skip the download and construct the image ID from datastore and filename.
  EOT
  type        = string
}

variable "image_checksum" {
  description = <<EOT
    Checksum value used to verify the integrity of the downloaded image.
    Required when `image_url` is set. Can be empty for manually uploaded images.
  EOT
  type        = string

  validation {
    condition     = var.image_url == "" || var.image_url == null || length(var.image_checksum) > 0
    error_message = "image_checksum must be provided when image_url is set."
  }
}

variable "image_checksum_algorithm" {
  description = <<EOT
    Algorithm used to validate the image checksum. Must be one of:
    `md5`, `sha1`, `sha224`, `sha256`, `sha384`, or `sha512`.
    Defaults to `sha256`.
  EOT
  type        = string
  default     = "sha256"
  validation {
    condition     = contains(["md5", "sha1", "sha224", "sha256", "sha384", "sha512"], var.image_checksum_algorithm)
    error_message = "Invalid checksum setting: ${var.image_checksum_algorithm}."
  }
}

variable "image_type" {
  description = <<EOT
    Content type of the image file. Must be either `iso` (for .iso, .img files)
    or `import` (for .raw, .qcow2, .vmdk files) for VM images or `vztmpl` for
    LXC images templates. Defaults to `iso`.
  EOT
  type        = string
  default     = "iso"

  validation {
    condition     = contains(["iso", "vztmpl", "import"], var.image_type)
    error_message = "Invalid content type: ${var.image_type}. Allowed: iso, vztmpl, import."
  }
}

variable "image_overwrite" {
  description = <<EOT
    Whether to overwrite an existing image file on the Proxmox node if it already exists.
    Set to `true` to force re-upload.
  EOT
  type        = bool
  default     = false
}

variable "image_upload_timeout" {
  description = <<EOT
    Timeout in seconds for uploading the image to the Proxmox node.
    Defaults to 600 seconds.
  EOT
  type        = number
  default     = 600
}
