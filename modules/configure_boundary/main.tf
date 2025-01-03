terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.2.0"
    }
  }
}

locals {
  boundary_addr    = "http://${var.boundary_ip_addr}:9200"
  vault_local_addr = "http://127.0.0.1:8200"
}

provider "boundary" {
  addr                   = local.boundary_addr
  auth_method_id         = var.auth_method_id
  auth_method_login_name = var.password_auth_method_login_name
  auth_method_password   = var.password_auth_method_password
}

resource "boundary_scope" "global" {
  global_scope = true
  name         = "global"
  description  = "Global Scope"
  scope_id     = "global"
}

resource "boundary_scope" "org" {
  name                     = "AT Computing"
  description              = "AT Computing Organization"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_role" "org_admin" {
  name          = "org_admins"
  description   = "Users that have all privileges within this org"
  principal_ids = [var.global_admin_id]
  grant_strings = ["ids=*;type=*;actions=*"]
  scope_id      = boundary_scope.org.id
}

resource "boundary_auth_method" "password" {
  scope_id = boundary_scope.org.id
  type     = "password"
}

resource "boundary_account_password" "guru" {
  auth_method_id = boundary_auth_method.password.id
  login_name     = var.guru_loginname
  password       = var.guru_password
}

resource "boundary_user" "guru" {
  name        = var.guru_loginname
  description = "AT user ${var.guru_loginname}"
  account_ids = [boundary_account_password.guru.id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_scope" "project" {
  name                   = "Demo"
  description            = "Demo project"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_role" "gurus" {
  name          = "gurus"
  description   = "Users that have all privileges within this project"
  principal_ids = [boundary_user.guru.id, var.global_admin_id]
  grant_strings = ["ids=*;type=*;actions=*"]
  scope_id      = boundary_scope.project.id
}

resource "boundary_credential_store_vault" "vault" {
  name        = "Vault Credential Store"
  description = "HashiCorp Vault"
  address     = local.vault_local_addr
  token       = var.vault_credential_store_token
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_library_vault_ssh_certificate" "vault" {
  name                = "Vault Credential Library"
  description         = "HashiCorp Vault"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh-client-signer/sign/boundary-client"
  username            = var.ssh_user
  key_type            = "ecdsa"
  key_bits            = 521

  extensions = {
    permit-pty = ""
  }
}

resource "boundary_host_catalog_static" "clients" {
  name        = "Clients"
  description = "test catalog"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host_static" "client" {
  name            = "Client"
  host_catalog_id = boundary_host_catalog_static.clients.id
  address         = var.boundary_client_private_ip
}

resource "boundary_host_set_static" "clients" {
  name            = "Clients Set"
  host_catalog_id = boundary_host_catalog_static.clients.id

  host_ids = [
    boundary_host_static.client.id
  ]
}

resource "boundary_target" "client" {
  name                     = "client"
  description              = "Demo client"
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  scope_id                 = boundary_scope.project.id
  egress_worker_filter     = " \"local\" in \"/tags/type\" "
  host_source_ids = [
    boundary_host_set_static.clients.id
  ]
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.vault.id
  ]
}

resource "boundary_alias_target" "client" {
  name                      = "Client Alias"
  value                     = var.boundary_target_alias
  scope_id                  = "global"
  destination_id            = boundary_target.client.id
  authorize_session_host_id = boundary_host_static.client.id
}
