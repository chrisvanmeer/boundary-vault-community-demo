variable "prefix" {
  default = "bvd"
}

variable "ssh_user" {
  default = "guru"
}

variable "ssh_public_key_file" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_file" {
  default = trimsuffix(var.ssh_public_key_file, ".pub")
}

variable "azure_resource_group_name" {
  default = "boundary-vault"
}

variable "azure_resource_group_location" {
  default = "westeurope"
}

variable "azure_instance_machine_type" {
  default = "Standard_B1s"
}

variable "azure_instance_image_offer" {
  default = "0001-com-ubuntu-server-focal"
}

variable "azure_instance_image_publisher" {
  default = "Canonical"
}

variable "azure_instance_image_sku" {
  default = "24_04-lts-gen2"
}

variable "azure_instance_image_version" {
  default = "latest"
}
