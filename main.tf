terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = false
  features {}
}

resource "azurerm_resource_group" "resource" {
  name     = "myGroup-resources"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "tf-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_machine" "main" {
  name                  = "tf-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "mydisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "admin"
    admin_password = "P@ssword123!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}


resource "azurerm_network_security_group" "secureGroup" {
  name                = "acceptanceTestSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "mysql"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}


resource "null_resource" "mysql2" {
  triggers = {
    order = azurerm_virtual_machine.main.id
  }
 

  provisioner "remote-exec" {
     connection {
        type="ssh"
        user="admin"
        password="P@ssword123!!"  
        host = azurerm_public_ip.example.ip_address
  }
      inline = [
      "sudo apt update",
      "sudo apt-get install -y mysql-server"
    ]
  }
}

