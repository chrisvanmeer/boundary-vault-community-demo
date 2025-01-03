output "boundary_ip_address" {
  value = azurerm_public_ip.server.ip_address
}

output "vault_ip_address" {
  value = azurerm_public_ip.server.ip_address
}

output "vault_token" {
  value = var.vault_dev_token
}

output "boundary_client_public_ip_address" {
  value = azurerm_public_ip.client.ip_address
}

output "boundary_client_private_ip_address" {
  value = var.azure_private_ip_address_client
}

output "boundary_client_id" {
  value = azurerm_linux_virtual_machine.client.id
}

output "boundary_login_name" {
  value = var.boundary_login_name
}

output "boundary_password" {
  value     = var.boundary_password
  sensitive = true
}

output "ssh_user" {
  value = var.ssh_user
}

output "ssh_public_key_file" {
  value = var.ssh_public_key_file
}
