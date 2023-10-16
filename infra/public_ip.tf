resource "azurerm_public_ip" "pip" {
  name                = local.pipName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.pipSubDomain

  tags = var.tags
}