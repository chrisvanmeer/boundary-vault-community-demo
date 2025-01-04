terraform {
  required_version = "~> 1.10.0"
}

# Deploy a server VM and a client VM
# On the server VM, docker, boundary-enterprise and vault will be installed
# The client VM will be just a vanilla install
module "deploy" {
  source                   = "./modules/deployment"
  prefix                   = var.prefix
  ssh_user                 = var.ssh_user
  ssh_public_key_file      = var.ssh_public_key_file
  boundary_hclic           = file(var.boundary_hclic)
  boundary_client_username = var.boundary_client_username
  restricted_nsg           = var.restricted_nsg
}

# Configure Vault with the SSH secrets engine
module "configure_vault" {
  source                   = "./modules/configure_vault"
  vault_ip_addr            = module.deploy.vault_ip_address
  vault_token              = module.deploy.vault_token
  boundary_client_username = var.boundary_client_username
}

# Configure the client with the CA signing key and sshd settings
module "configure_client" {
  source                            = "./modules/configure_client"
  ssh_user                          = module.deploy.ssh_user
  ssh_public_key_file               = module.deploy.ssh_public_key_file
  boundary_client_id                = module.deploy.boundary_client_id
  boundary_client_public_ip_address = module.deploy.boundary_client_public_ip_address
  vault_ca_public_key               = module.configure_vault.vault_ca_public_key
}

# Configure Boundary with an Org, Project, Credential Library, Host set, Target and Alias
module "configure_boundary" {
  source                          = "./modules/configure_boundary"
  boundary_ip_addr                = module.deploy.boundary_ip_address
  password_auth_method_login_name = module.deploy.boundary_login_name
  password_auth_method_password   = module.deploy.boundary_password
  boundary_client_private_ip      = module.deploy.boundary_client_private_ip_address
  vault_credential_store_token    = module.configure_vault.vault_credential_store_token
  boundary_client_username        = var.boundary_client_username
}
