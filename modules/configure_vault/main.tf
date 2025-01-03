terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.5.0"
    }
  }
}

locals {
  vault_address = "http://${var.vault_ip_addr}:8200"
}

provider "vault" {
  address = local.vault_address
  token   = var.vault_token
}

resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = <<EOT
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
path "auth/token/revoke-self" {
  capabilities = ["update"]
}
path "sys/leases/renew" {
  capabilities = ["update"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOT
}
resource "vault_policy" "ssh" {
  name = "ssh"

  policy = <<EOT
path "ssh-client-signer/issue/boundary-client" {
  capabilities = ["create", "update"]
}
path "ssh-client-signer/sign/boundary-client" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_mount" "ssh" {
  path = "ssh-client-signer"
  type = "ssh"
}

resource "vault_ssh_secret_backend_role" "boundary_client" {
  name                    = "boundary-client"
  backend                 = vault_mount.ssh.path
  key_type                = "ca"
  allow_user_certificates = true
  default_user            = var.boundary_client_username
  default_extensions = {
    "permit-pty" = ""
  }
  allowed_users      = "*"
  allowed_extensions = "*"
}

resource "vault_ssh_secret_backend_ca" "ca" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_token" "cred_store" {
  policies          = ["boundary-controller", "ssh"]
  period            = "24h"
  renewable         = true
  no_default_policy = true
  no_parent         = true
}
