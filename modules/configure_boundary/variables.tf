variable "boundary_ip_addr" {
  type        = string
  description = "The IP address of the Boundary Controller"
}

variable "boundary_client_private_ip" {
  type        = string
  description = "The internal IP address of the demo client"
}

variable "vault_credential_store_token" {
  type        = string
  description = "Vault token for the SSH credential store"
}

variable "auth_method_id" {
  type        = string
  description = "The auth method ID"
  default     = "ampw_1234567890"
}

variable "password_auth_method_login_name" {
  type        = string
  description = "The admin user you want to log in with"
  default     = "admin"
}

variable "password_auth_method_password" {
  type        = string
  description = "The password you want to log in with"
  default     = "password"
}

variable "global_admin_id" {
  type        = string
  description = "The global admin ID that you want to include with the new org and projects"
  default     = "u_1234567890"
}

variable "guru_loginname" {
  type        = string
  description = "The user login name?"
  default     = "bounbdary-guru"
}

variable "guru_password" {
  type        = string
  description = "The password for the guru's"
  default     = "p@ssw0rd"
  sensitive   = true
}

variable "boundary_target_alias" {
  type        = string
  description = "The actual FQDN you will be accessing"
  default     = "client.boundary"
}

variable "ssh_user" {
  type        = string
  description = "The SSH user to connect to the client"
}
