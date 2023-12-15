data "azurerm_role_definition" "sa_blob_contributor" {
  name = "Storage Blob Data Contributor"
}

data "azurerm_role_definition" "sa_key_operator" {
  name = "Storage Account Key Operator Service Role"
}

data "azurerm_role_definition" "sa_reader_and_data_access" {
  name = "Reader and Data Access"
}

# RABC Rights for Function to Storage Account

resource "azurerm_role_assignment" "rbacfnsablob" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.sa_blob_contributor.name
}

resource "azurerm_role_assignment" "rbacfnsakeyop" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.sa_key_operator.name
}

resource "azurerm_role_assignment" "rbacfnsadataaccess" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.sa_reader_and_data_access.name
}

# RABC Rights for Function to Event Hubs

data "azurerm_role_definition" "event_hubs_owner" {
  name = "Azure Event Hubs Data Owner"
}

# Assign the Event Hubs Data Owner role to the Function App's identity on the Event Hubs Namespace
resource "azurerm_role_assignment" "rbacfneh" {
  scope                = azurerm_eventhub_namespace.eh.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.event_hubs_owner.name
}

# RABC Rights for Function to Key Vault

data "azurerm_role_definition" "keyvault_secrets_user" {
  name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "rbacfnkv" {
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_windows_function_app.fn.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_user.name
}

# RABC Rights for APIM to Key Vault

resource "azurerm_role_assignment" "rbacapimkv" {
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_api_management.apim.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.keyvault_secrets_user.name
}
