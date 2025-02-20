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
    subnets_cidrs = cidrsubnets( tolist(azurerm_virtual_network.vnet.address_space)[0]  ,[for i in values(var.subnets) : i - local.vnet_address_space_size]... )
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
}



resource "azurerm_network_security_group" "nsg" {
  for_each             = local.subnets
  name                 = "${module.naming.network_security_group.name}-${each.key}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  for_each                 = local.subnets
  subnet_id                = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}


# resource "azurerm_subnet" "subnet-vms" {
#   name                 = "${module.naming.subnet.name}-vms"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = [cidrsubnet(azurerm_virtual_network.vnet.address_space, var.subnet_size, 0)]
# }




# resource "azurerm_network_security_group" "nsg-subnet-vms" {
#   name                = "${module.naming.network_security_group.name}-subnet-vms"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule {
#     name                       = "AllowSSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
#   subnet_id                 = azurerm_subnet.subnet-vms.id
#   network_security_group_id = azurerm_network_security_group.nsg-subnet-vms.id
# }

