variable "boundary_hclic" {
  type        = string
  description = "The path to the license file"
  default     = "./boundary.hclic"
  sensitive   = true

  validation {
    condition     = fileexists(var.boundary_hclic)
    error_message = "The path to the license file \"${var.boundary_hclic}\" does not exist."
  }
}

variable "ssh_user" {
  type        = string
  description = "The SSH username that will be created on the server"
  default     = "guru"
}

variable "ssh_public_key_file" {
  type        = string
  description = "The SSH public key that will be added to the ssh_user's authorized_keys file"
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = fileexists(var.ssh_public_key_file)
    error_message = "The \"${var.ssh_public_key_file}\" does not exist."
  }
}
