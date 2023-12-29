resource "azurerm_resource_group" "rg" {
  name     = local.resourceGroupName
  location = var.location

  tags = var.tags
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}