terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  ssh_private_key_file = trimsuffix(var.ssh_public_key_file, ".pub")
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_resource_group_location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "server" {
  name                = "${var.prefix}-public_ip-server"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "client" {
  name                = "${var.prefix}-public_ip-client"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_server" {
  name                = "${var.prefix}-nic-server"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "eth0"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.azure_private_ip_address_server
    public_ip_address_id          = azurerm_public_ip.server.id
  }
}

resource "azurerm_network_interface" "nic_client" {
  name                = "${var.prefix}-nic-client"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "eth0"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.azure_private_ip_address_client
    public_ip_address_id          = azurerm_public_ip.client.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "allow_boundary"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200-9203"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_vault"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200-8201"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_ssh"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "server" {
  name                = "${var.prefix}-vm-server"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.azure_instance_machine_type
  admin_username      = var.ssh_user

  network_interface_ids = [azurerm_network_interface.nic_server.id]

  source_image_reference {
    publisher = var.azure_instance_image_publisher
    offer     = var.azure_instance_image_offer
    sku       = var.azure_instance_image_sku
    version   = var.azure_instance_image_version
  }

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    name                 = "${var.prefix}-vm-server-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Install packages
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y gnupg2",
      "wget -q -O /tmp/hashicorp.gpg https://apt.releases.hashicorp.com/gpg",
      "sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg /tmp/hashicorp.gpg",
      "rm /tmp/hashicorp.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io boundary-enterprise vault",
      "echo 'BOUNDARY_LICENSE=${var.boundary_hclic}' | sudo tee /etc/boundary.d/boundary.env"
    ]

    connection {
      type     = "ssh"
      host     = self.public_ip_address
      user     = var.ssh_user
      password = local.ssh_private_key_file
      timeout  = "2m"
    }
  }

  # Start Vault
  provisioner "remote-exec" {
    inline = [
      "echo '[Unit]' | sudo tee /etc/systemd/system/vaultdev.service",
      "echo 'Description=Vault Dev Server' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo 'After=network.target' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo '' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo 'ExecStart=/usr/bin/vault server -dev -dev-root-token-id=${var.vault_dev_token} -dev-listen-address=0.0.0.0:8200' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo 'Restart=always' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo 'User=root' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo '' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/vaultdev.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now vaultdev.service"
    ]
    connection {
      type     = "ssh"
      host     = self.public_ip_address
      user     = var.ssh_user
      password = local.ssh_private_key_file
      timeout  = "2m"
    }
  }

  # Start Boundary
  provisioner "remote-exec" {
    inline = [
      "echo '[Unit]' | sudo tee /etc/systemd/system/boundarydev.service",
      "echo 'Description=Boundary Dev Server' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'After=network.target' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo '' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo '[Service]' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'EnvironmentFile=-/etc/boundary.d/boundary.env' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'ExecStart=/usr/bin/boundary dev -api-listen-address=0.0.0.0 -proxy-listen-address=0.0.0.0 -login-name=${var.boundary_login_name} -password=${var.boundary_password} -worker-public-address=${azurerm_public_ip.server.ip_address}' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'Restart=always' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'User=root' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo '' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo '[Install]' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "echo 'WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/boundarydev.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now boundarydev.service"
    ]
    connection {
      type     = "ssh"
      host     = self.public_ip_address
      user     = var.ssh_user
      password = local.ssh_private_key_file
      timeout  = "2m"
    }
  }
}

resource "azurerm_linux_virtual_machine" "client" {
  name                = "${var.prefix}-vm-client"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.azure_instance_machine_type
  admin_username      = var.ssh_user

  network_interface_ids = [azurerm_network_interface.nic_client.id]

  source_image_reference {
    publisher = var.azure_instance_image_publisher
    offer     = var.azure_instance_image_offer
    sku       = var.azure_instance_image_sku
    version   = var.azure_instance_image_version
  }

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    name                 = "${var.prefix}-vm-client-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
