variable "ssh_user" {
  type        = string
  description = "The SSH user to connect to the client"
}

variable "ssh_public_key_file" {
  type        = string
  description = "The SSH public key that will be added to the ssh_user's authorized_keys file"
}

variable "boundary_client_public_ip_address" {
  type        = string
  description = "The public IP address of the demo client"
}

variable "boundary_client_id" {
  type        = string
  description = "The Azure ID of the demo client"
}

variable "vault_ca_public_key" {
  type        = string
  description = "The CA public key to trust from Vault"
}

variable "vault_ca_public_key_location" {
  type        = string
  description = "The location of the CA public key to trust from Vault"
  default     = "/etc/ssh/boundary-ca-key.pub"
}

variable "ssh_config_file_boundary" {
  type        = string
  description = "The config file specifying Boundary stuff"
  default     = "/etc/ssh/sshd_config.d/boundary.conf"

}
