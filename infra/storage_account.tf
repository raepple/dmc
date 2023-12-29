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

resource "azurerm_storage_container" "deploy" {
  name                  = "deploy"
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

resource "azurerm_storage_blob" "pic2" {
  name                   = "Ragul02__Steuerkopf_oben_469.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_469.jpg"
}

resource "azurerm_storage_blob" "pic3" {
  name                   = "Ragul02__Steuerkopf_oben_472.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_472.jpg"
}

resource "azurerm_storage_blob" "pic4" {
  name                   = "Ragul02__Steuerkopf_oben_483.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_483.jpg"
}

resource "azurerm_storage_blob" "pic5" {
  name                   = "Ragul02__Steuerkopf_oben_485.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_485.jpg"
}

resource "azurerm_storage_blob" "pic6" {
  name                   = "Ragul02__Steuerkopf_oben_488.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_488.jpg"
}

resource "azurerm_storage_blob" "pic7" {
  name                   = "Ragul02__Steuerkopf_oben_490.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_490.jpg"
}

resource "azurerm_storage_blob" "pic8" {
  name                   = "Ragul02__Steuerkopf_oben_511.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_511.jpg"
}

resource "azurerm_storage_blob" "pic9" {
  name                   = "Ragul02__Steuerkopf_oben_523.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_523.jpg"
}

resource "azurerm_storage_blob" "pic10" {
  name                   = "Ragul02__Steuerkopf_oben_526.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_526.jpg"
}

resource "azurerm_storage_blob" "pic11" {
  name                   = "Ragul02__Steuerkopf_oben_529.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_529.jpg"
}

resource "azurerm_storage_blob" "pic12" {
  name                   = "Ragul02__Steuerkopf_oben_544.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_544.jpg"
}

resource "azurerm_storage_blob" "pic13" {
  name                   = "Ragul02__Steuerkopf_oben_546.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul02__Steuerkopf_oben_546.jpg"
}

resource "azurerm_storage_blob" "pic14" {
  name                   = "Ragul04__Steuerkopf_oben_582.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul04__Steuerkopf_oben_582.jpg"
}

resource "azurerm_storage_blob" "pic15" {
  name                   = "Ragul04__Steuerkopf_oben_584.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul04__Steuerkopf_oben_584.jpg"
}

resource "azurerm_storage_blob" "pic16" {
  name                   = "Ragul04__Steuerkopf_oben_589.jpg"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.pictures.name
  type                   = "Block"
  source                 = "./upload/Ragul04__Steuerkopf_oben_589.jpg"
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}