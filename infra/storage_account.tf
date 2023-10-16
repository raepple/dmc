resource "azurerm_storage_account" "sa" {
  name                     = local.storageAccountName
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_storage_container" "pictures" {
  name                  = "pictures"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "raw-picutres" {
  name                  = "raw-picutres"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

