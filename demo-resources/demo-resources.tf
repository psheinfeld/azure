resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = var.azure_region
}


resource "azurerm_virtual_network" "vnet" {
  name                = module.naming.virtual_network.name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

locals {
    vnet_address_space_size = tonumber(split("/", tolist(azurerm_virtual_network.vnet.address_space)[0])[1])
    subnets_cidrs = cidrsubnets( tolist(azurerm_virtual_network.vnet.address_space)[0]  ,[for i in values(var.subnets) : i.size - local.vnet_address_space_size]... )
    subnets = zipmap(keys(var.subnets), local.subnets_cidrs)
}

output "subnets" {
  value = local.subnets
}


resource "azurerm_subnet" "subnets" {
  for_each             =  local.subnets
  name                 = "${module.naming.subnet.name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
  default_outbound_access_enabled = var.subnets[each.key].default_outbound_access_enabled
}



resource "azurerm_network_security_group" "nsg" {
  for_each             = local.subnets
  name                 = "${module.naming.network_security_group.name}-${each.key}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  dynamic "security_rule" {
    for_each = lookup(var.subnets[each.key], "nsg_rules", [])
    content {
      name                       = (var.network_security_group_rules[security_rule.value]).name
      priority                   = (var.network_security_group_rules[security_rule.value]).priority
      direction                  = (var.network_security_group_rules[security_rule.value]).direction
      access                     = (var.network_security_group_rules[security_rule.value]).access
      protocol                   = (var.network_security_group_rules[security_rule.value]).protocol
      source_port_range          = (var.network_security_group_rules[security_rule.value]).source_port_range
      destination_port_range     = (var.network_security_group_rules[security_rule.value]).destination_port_range
      source_address_prefix      = (var.network_security_group_rules[security_rule.value]).source_address_prefix
      destination_address_prefix = (var.network_security_group_rules[security_rule.value]).destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  for_each                 = local.subnets
  subnet_id                = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}





resource "azurerm_network_interface" "vm_nic" {
  for_each             = var.virtual_machines
  name                 = "${module.naming.network_interface.name}-${each.value.name}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet_name].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip ? azurerm_public_ip.vm_pip[each.key].id : null
  }
}

resource "azurerm_public_ip" "vm_pip" {
  for_each             = { for k, v in var.virtual_machines : k => v if v.public_ip }
  name                 = "${module.naming.public_ip.name}-${each.value.name}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  allocation_method    = "Static"
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each             = var.virtual_machines
  name                 = "${module.naming.virtual_machine.name}-${each.value.name}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  size                 = each.value.size
  admin_username       = each.value.username
  computer_name        = each.value.name

  network_interface_ids = [
    azurerm_network_interface.vm_nic[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  admin_ssh_key {
    username   = each.value.username
    public_key = var.ssh_public_key
  }

  custom_data = base64encode(file("${path.module}/${each.value.cloud_init.user_data}"))


  identity {
    type = "SystemAssigned"
  }

}