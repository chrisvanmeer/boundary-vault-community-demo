
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_resource_group_location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.name
  resource_group_name = azurerm_resource_group.resource_group.location
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "azure_public_ip" {
  name                = "public_ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic_server" {
  name                = "${var.prefix}-nic-server"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.10"
    public_ip_address_id          = azurerm_public_ip.azure_public_ip.id
  }
}

resource "azurerm_network_interface" "nic_client" {
  name                = "${var.prefix}-nic-client"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.20"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "allow_boundary"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200-9201"
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

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.nic_server.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "server" {
  name                = "${var.prefix}-server"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.azure_instance_machine_type
  admin_username      = var.ssh_user

  network_interface_ids = [azurerm_network_interface.nic_server]

  source_image_reference {
    offer     = var.azure_instance_image_offer
    publisher = var.azure_instance_image_publisher
    sku       = var.azure_instance_image_sku
    version   = var.azure_instance_image_version
  }

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}

resource "azurerm_linux_virtual_machine" "client" {
  name                = "${var.prefix}-client"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.azure_instance_machine_type
  admin_username      = var.ssh_user

  network_interface_ids = [azurerm_network_interface.nic_client]

  source_image_reference {
    offer     = var.azure_instance_image_offer
    publisher = var.azure_instance_image_publisher
    sku       = var.azure_instance_image_sku
    version   = var.azure_instance_image_version
  }

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
