output "vault_credential_store_token" {
  value     = vault_token.cred_store.client_token
  sensitive = true
}

output "vault_ca_public_key" {
  value = vault_ssh_secret_backend_ca.ca.public_key
}
