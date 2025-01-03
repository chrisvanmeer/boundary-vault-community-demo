variable "vault_ip_addr" {
  type        = string
  description = "The IP address of the Vault Server (same as Boundary Controller)"
}

variable "vault_token" {
  type        = string
  description = "The token used to authenticate to Vault"
  sensitive   = true
}

variable "vault_ssh_secrets_engine_mount" {
  type        = string
  description = "The mount path of the SSH secrets engine"
  default     = "ssh"
}

variable "ssh_user" {
  type        = string
  description = "The SSH user to connect to the client"
}
