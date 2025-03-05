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
  type        = map(object({
    size       = number
    default_outbound_access_enabled  = bool
    nsg_rules = optional(list(string),[])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
  default     = {
    vm = {size = 24 , nsg_rules=["allow_ssh_from_anywhere","allow_80"] ,  default_outbound_access_enabled = false}
    db = {size = 25 , default_outbound_access_enabled = false} 
    aks = {size = 23 , default_outbound_access_enabled = false}
  }
}

variable "virtual_machines" {
  description = "Map of VM names and their sizes"
  type        = map(object({
    name        = string
    size       = string
    subnet_name = string
    username    = optional(string, "auser")
    public_ip  = optional(bool, false)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    cloud_init = optional(object({
      user_data = string
    }))
  }))
  default = {
    "apache" = {
      name        = "apache"
      size        = "Standard_D2s_v3"
      subnet_name = "vm"
      public_ip   = true
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
      }
      # source_image_reference = {
      #   publisher = "Canonical"
      #   offer     = "ubuntu-24_04-lts"
      #   sku       = "server"
      #   version   = "latest"
      # }
      
      cloud_init = {
        user_data = "cloud-init/apache.yaml"
      }
    }
  }
  
}