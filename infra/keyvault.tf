resource "azurerm_key_vault" "kv" {
  name                        = local.kvName
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = var.tags
}

locals {
  kvsecrets = {
    "CustomVisionKey" = azurerm_cognitive_account.cs.primary_access_key
    "EventHubConnectionAppSetting" = azurerm_eventhub_namespace.eh.default_primary_connection_string
    "DMOAuthClientID" = cloudfoundry_service_key.dmkey.credentials.uaa_clientid
    "DMOAuthClientSecret" = cloudfoundry_service_key.dmkey.credentials.uaa_clientsecret
    "FunctionAppHostKey" = data.azurerm_function_app_host_keys.fnkeys.default_function_key
  }
}

resource "azurerm_key_vault_secret" "kvsecrets" {
  for_each     = local.kvsecrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "password"
}

resource "azurerm_key_vault_access_policy" "kvapfn" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_function_app.fn.identity.0.principal_id

  secret_permissions = [
    "Get",
    "Set",
    "List"
  ]
}

resource "azurerm_key_vault_access_policy" "kvapapim" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_api_management.apim.identity.0.principal_id

  secret_permissions = [
    "Get",
    "Set",
    "List"
  ]
}

# needed for reference in API management
data "azurerm_key_vault_secret" "fnhk" {
  name         = "FunctionAppHostKey"
  key_vault_id = azurerm_key_vault.kv.id
}