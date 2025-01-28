terraform {
  backend "azurerm" {
    resource_group_name   = var.state_resource_group_name
    storage_account_name  = var.state_storage_account_name
    container_name        = var.state_container_name
    key                   = var.state_key
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "alb-chain" {
  name     = "alb-chain-resources"
  location = "Sweden Central"
}

resource "azurerm_virtual_network" "alb-chain" {
  name                = "alb-chain-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.alb-chain.location
  resource_group_name = azurerm_resource_group.alb-chain.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.alb-chain.name
  virtual_network_name = azurerm_virtual_network.alb-chain.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "alb-chain" {
  name                = "alb-chain-nic"
  location            = azurerm_resource_group.alb-chain.location
  resource_group_name = azurerm_resource_group.alb-chain.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "alb-chain" {
  name                = "alb-chain-vm"
  resource_group_name = azurerm_resource_group.alb-chain.name
  location            = azurerm_resource_group.alb-chain.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.alb-chain.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key
  }

  tags = {
    environment = "demo"
  }
}

resource "azurerm_public_ip" "alb-chain" {
  name                = "alb-chain-pip"
  location            = azurerm_resource_group.alb-chain.location
  resource_group_name = azurerm_resource_group.alb-chain.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "alb-chain" {
  name                = "alb-chain-lb"
  location            = azurerm_resource_group.alb-chain.location
  resource_group_name = azurerm_resource_group.alb-chain.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.alb-chain.id
  }
}

resource "azurerm_lb_backend_address_pool" "alb-chain" {
#   resource_group_name = azurerm_resource_group.alb-chain.name
  loadbalancer_id     = azurerm_lb.alb-chain.id
  name                = "BackendAddressPool"
}

resource "azurerm_lb_probe" "alb-chain" {
#   resource_group_name = azurerm_resource_group.alb-chain.name
  loadbalancer_id     = azurerm_lb.alb-chain.id
  name                = "ssh-probe"
  protocol            = "Tcp"
  port                = 22
}

resource "azurerm_lb_rule" "alb-chain" {
#  resource_group_name            = azurerm_resource_group.alb-chain.name
  loadbalancer_id                = azurerm_lb.alb-chain.id
  name                           = "SSHLoadBalancerRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.alb-chain.id]
  probe_id                       = azurerm_lb_probe.alb-chain.id

  
}

resource "azurerm_network_interface_backend_address_pool_association" "alb-chain" {
  network_interface_id    = azurerm_network_interface.alb-chain.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.alb-chain.id
}