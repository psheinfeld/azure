module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix = [ var.customer_name , var.application_name, var.azure_region]
}
