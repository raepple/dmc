resource "azurerm_storage_account" "sa" {
  name                            = local.storageAccountName
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
    
  network_rules {           
    default_action              = "Deny"
    bypass                      = ["AzureServices"]
    virtual_network_subnet_ids  = []
    ip_rules                    = var.white_list_ip
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# create blob containers for the scenario
resource "azurerm_storage_container" "pictures" {
  name                  = "pictures"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "raw-pictures" {
  name                  = "raw-pictures"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# upload sample pictures for the mocked industry camera
resource "azurerm_storage_blob" "pic1" {
  name                   = "Ragul02__Steuerkopf_oben_453.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_453.jpg"
}
