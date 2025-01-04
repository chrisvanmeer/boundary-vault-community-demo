terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

locals {
  ssh_private_key_file = file(trimsuffix(var.ssh_public_key_file, ".pub"))
}

resource "null_resource" "ca_key" {
  triggers = {
    client_id = var.boundary_client_id
  }
  provisioner "file" {
    content     = var.vault_ca_public_key
    destination = "/tmp/ca-key.pub"

    connection {
      host        = var.boundary_client_public_ip_address
      user        = var.ssh_user
      private_key = local.ssh_private_key_file
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/ca-key.pub ${var.vault_ca_public_key_location}",
      "sudo chmod 0644 ${var.vault_ca_public_key_location}",
      "echo 'TrustedUserCAKeys ${var.vault_ca_public_key_location}' | sudo tee -a ${var.ssh_config_file_boundary}",
      "echo 'PermitTTY yes' | sudo tee -a ${var.ssh_config_file_boundary}",
      "echo 'X11Forwarding yes' | sudo tee -a ${var.ssh_config_file_boundary}",
      "echo 'X11UseLocalhost no' | sudo tee -a ${var.ssh_config_file_boundary}",
      "sudo systemctl restart sshd"
    ]

    connection {
      host        = var.boundary_client_public_ip_address
      user        = var.ssh_user
      private_key = local.ssh_private_key_file
    }
  }
}
