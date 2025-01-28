variable "subscription_id" {
  description = "subscription id"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "state_subscription_id" {
  description = "TF state subscription id"
  type        = string
}
variable "state_resource_group_name" {
  description = "TF state resource group name"
  type        = string
}

variable "state_storage_account_name" {
  description = "TF state storage account name"
  type        = string
}
variable "state_container_name" {    
  description = "TF state container name"
  type        = string 
}
variable "state_key" {
  description = "TF state key"
  type        = string
}