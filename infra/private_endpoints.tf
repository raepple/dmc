resource "azurerm_private_dns_zone" "private_dns_zone" {
  for_each            = local.dns_zones
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  for_each              = local.dns_zones
  name                  = "vnet-${each.key}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "storage_private_endpoints" {
  for_each            = toset(local.storage_subresources)
  name                = "${local.storageAccountName}-${each.key}-pep"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pepsubnet.id

  private_service_connection {
    name                           = "${local.storageAccountName}-${each.key}-psc"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = [each.key]
  }

  private_dns_zone_group {
    name                 = "${each.key}-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone[each.key].id]
  }
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "${local.kvName}-pep"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pepsubnet.id

  private_service_connection {
    name                           = "${local.kvName}-psc"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["kv"].id]
  }
}

resource "azurerm_private_endpoint" "fnapp_private_endpoint" {
  name                = "${local.functionAppName}-pep"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pepsubnet.id

  private_service_connection {
    name                           = "${local.functionAppName}-psc"
    private_connection_resource_id = azurerm_windows_function_app.fn.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "fnapp-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["fnapp"].id]
  }
}

resource "azurerm_private_endpoint" "cognitiveservices_private_endpoint" {
  name                = "${local.csName}-pep"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pepsubnet.id

  private_service_connection {
    name                           = "${local.csName}-psc"
    private_connection_resource_id = azurerm_cognitive_account.cs.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "cs-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["cs"].id]
  }
}

resource "azurerm_private_endpoint" "eventhub_private_endpoint" {
  name                = "${local.eventHubName}-pep"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pepsubnet.id

  private_service_connection {
    name                           = "${local.eventHubName}-psc"
    private_connection_resource_id = azurerm_eventhub_namespace.eh.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "eh-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["eh"].id]
  }
}
