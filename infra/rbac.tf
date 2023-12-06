data "azurerm_role_definition" "blob_contributor" {
  name = "Storage Blob Data Contributor"
}

# Assign the Storage Account Data Contributor role to the Function App's identity on the Storage Account
resource "azurerm_role_assignment" "rbacfnsa" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.blob_contributor.name
}

data "azurerm_role_definition" "event_hubs_owner" {
  name = "Azure Event Hubs Data Owner"
}

# Assign the Event Hubs Data Owner role to the Function App's identity on the Event Hubs Namespace
resource "azurerm_role_assignment" "rbacfneh" {
  scope                = azurerm_eventhub_namespace.eh.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.event_hubs_owner.name
}

data "azurerm_role_definition" "keyvault_secrets_user" {
  name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "rbacfnkv" {
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_user.name
}

resource "azurerm_role_assignment" "rbacapimkv" {
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_api_management.apim.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_user.name
}
