resource "azurerm_cognitive_account" "cs" {
  name                = local.csName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "CognitiveServices"
  custom_subdomain_name = local.csSubDomain

  sku_name = var.cs_sku

  tags = var.tags
}