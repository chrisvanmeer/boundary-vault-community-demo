variable "prefix" {
  type        = string
  description = "The prefix for every resource"
}

variable "ssh_user" {
  type        = string
  description = "The SSH username that will be created on the server"
}

variable "ssh_public_key_file" {
  type        = string
  description = "The SSH public key that will be added to the ssh_user's authorized_keys file"
}

variable "azure_resource_group_name" {
  type        = string
  description = "The name of the resource group that will be created"
  default     = "boundary-vault-demo"
}

variable "azure_resource_group_location" {
  type        = string
  description = "The location for the resource group"
  default     = "westeurope"
}

variable "azure_instance_machine_type" {
  type        = string
  description = "The machine size"
  default     = "Standard_B1s"
}

variable "azure_instance_image_publisher" {
  type        = string
  description = "Source image reference publisher"
  default     = "Debian"
}

variable "azure_instance_image_offer" {
  type        = string
  description = "Source image reference offer"
  default     = "debian-12"
}

variable "azure_instance_image_sku" {
  type        = string
  description = "Source image reference sku"
  default     = "12"
}

variable "azure_instance_image_version" {
  type        = string
  description = "Source image reference version"
  default     = "latest"
}

variable "azure_private_ip_address_server" {
  type        = string
  description = "The internal IP address of the server"
  default     = "10.0.2.10"
}

variable "azure_private_ip_address_client" {
  type        = string
  description = "The internal IP address of the client"
  default     = "10.0.2.20"
}

variable "vault_dev_token" {
  type        = string
  description = "The Vault token which gets the root policy assigned"
  default     = "guru"
}

variable "boundary_login_name" {
  type        = string
  description = "The full on admin that gets access to Boundary"
  default     = "admin"
}

variable "boundary_password" {
  type        = string
  description = "The full on admin password that gets access to Boundary"
  default     = "password"
}

variable "boundary_hclic" {
  type        = string
  description = "The license file"
  sensitive   = true
}
