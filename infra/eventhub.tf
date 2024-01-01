resource "azurerm_eventhub_namespace" "eh" {
  name                = local.eventHubName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.eh_sku
  capacity            = 1

  # allow traffic only from the private endpoint
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_eventhub" "eh_picanareq" {
  name                = "picture-analysis-requests"
  namespace_name      = azurerm_eventhub_namespace.eh.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub" "eh_picanares" {
  name                = "picture-analysis-results"
  namespace_name      = azurerm_eventhub_namespace.eh.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "eh_cg_todmcpub" {
  name                = "to-dmc-publisher"
  namespace_name      = azurerm_eventhub_namespace.eh.name
  eventhub_name       = azurerm_eventhub.eh_picanares.name
  resource_group_name = azurerm_resource_group.rg.name
}