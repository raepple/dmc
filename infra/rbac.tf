# Assign the Storage Account Data Contributor role to the Function App's identity on the Storage Account
resource "azurerm_role_assignment" "rbacfnsa" {
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.sa.id
}

# Assign the Event Hubs Data Owner role to the Function App's identity on the Event Hubs Namespace
resource "azurerm_role_assignment" "rbacfneh" {
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = "Azure Event Hubs Data Owner"
  scope                = azurerm_eventhub_namespace.eh.id
}

resource "azurerm_role_assignment" "rbacfnkv" {
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "rbacapimkv" {
  principal_id         = azurerm_api_management.apim.identity.0.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kv.id
}
