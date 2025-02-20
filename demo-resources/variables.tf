variable "create_vm" {
  description = "Do you want to create a VM? (yes/no)"
  type        = string
  default     = "no"
}

variable "vm_size" {
  description = "The size of the VM? (eg. Standard_D2s_v3)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "number_of_vms" {
  description = "The number of VMs to create"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "The public SSH key to use for the VM"
  type        = string
  default     = "none"
}

variable "customer_name" {
  type        = string
  default = "none"
}

variable "application_name" {
  type        = string
  default = "none"
}

variable "azure_region" {
  type        = string
  default = "none"
}

variable "subscription_id" {
  type        = string
  default = "000-0000"
}


variable "vnet_address_space" {
  description = "The address space for the VNet (e.g. 172.16.0.0/16)"
  type        = string
  default     = "172.16.0.0/16"
}


variable "subnets" {
  description = "Map of subnet names and their sizes, (e.g. vms=25, db=25, aks=8, web=8)"
  type        = map(number)
  default     = {
    vms = 25
    db  = 25
    aks = 24
    web = 23
  }
}

# variable "network_security_group_rules" {
#   description = "Map of network security group rules"
#   type        = list(map(object({
#     name                       = string
#     priority                   = number
#     direction                  = string
#     access                     = string
#     protocol                   = string
#     source_port_range          = string
#     destination_port_range     = string
#     source_address_prefix      = string
#     destination_address_prefix = string
#   })))
#   default     = (
#     allow_ssh = {
#       name                       = "AllowSSH"
#       priority                   = 1001
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "*"
#       destination_port_range     = "22"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     }
#   )
# }

