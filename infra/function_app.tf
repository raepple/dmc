resource "azurerm_service_plan" "sp" {
  name                = local.appServicePlanName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = var.sp_sku

  tags = var.tags
}

locals {
  appsettings = {
    "COGNITIVE_SERVICES_CUSTOM_VISION_ENDPOINT" = azurerm_cognitive_account.cs.endpoint
    "COGNITIVE_SERVICES_CUSTOM_VISION_SUBSCRIPTION_KEY" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=CustomVisionKey)")
    "COGNITIVE_SERVICES_CUSTOM_VISION_PROJECT_GUID" = "1ad542fa-e828-48f1-bc07-e5ca8000b278"
    "COGNITIVE_SERVICES_CUSTOM_VISION_MODEL_NAME" = "Iteration1"
    "DM_TOKEN_ENDPOINT" = format("%s%s",cloudfoundry_service_key.dmkey.credentials.uaa_url,"/oauth/token")
    "DM_OAUTH_CLIENT_ID" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=DMOAuthClientID)")
    "DM_OAUTH_CLIENT_SECRET" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=DMOAuthClientSecret)")
    "DM_INSPECTION_LOG_ENDPOINT" = format("%s%s", cloudfoundry_service_key.dmkey.credentials.public-api-endpoint, "/aiml/v1/inspectionLog")
    "PICTURE_STORAGE_ACCOUNT_ENDPOINT" = azurerm_storage_account.sa.primary_blob_endpoint
    "AzureWebJobsPICTURE_STORAGE_ACCOUNT_ENDPOINT__serviceUri" = azurerm_storage_account.sa.primary_blob_endpoint
    "EventHubConnectionAppSetting" = azurerm_eventhub_namespace.eh.default_primary_connection_string
  }
}

resource "azurerm_windows_function_app" "fn" {
  name                = local.functionAppName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_key = azurerm_application_insights.appinsights.instrumentation_key
  }

  app_settings = local.appsettings

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"], # prevent TF reporting configuration drift after app code is deployed
    ]
  }
}

data "azurerm_function_app_host_keys" "fnkeys" {
  name                = azurerm_windows_function_app.fn.name
  resource_group_name = azurerm_resource_group.rg.name
}
