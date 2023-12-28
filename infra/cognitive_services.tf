resource "azurerm_cognitive_account" "cs" {
  name                = local.csName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "CognitiveServices"
  custom_subdomain_name = local.csSubDomain

  identity {
    type = "SystemAssigned"
  }
  
  network_acls {
    default_action = "Deny"
    ip_rules = var.white_list_ip
  }

  sku_name = var.cs_sku

  tags = var.tags
}