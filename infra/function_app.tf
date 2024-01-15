locals {
  appsettings = {
    "COGNITIVE_SERVICES_CUSTOM_VISION_ENDPOINT" = azurerm_cognitive_account.cs.endpoint
    "COGNITIVE_SERVICES_CUSTOM_VISION_SUBSCRIPTION_KEY" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=CustomVisionKey)")
    "COGNITIVE_SERVICES_CUSTOM_VISION_PROJECT_GUID" = var.cs_projectid
    "COGNITIVE_SERVICES_CUSTOM_VISION_MODEL_NAME" = "Iteration1"
    "DM_TOKEN_ENDPOINT" = format("%s%s",cloudfoundry_service_key.dmkey.credentials.uaa_url,"/oauth/token")
    "DM_OAUTH_CLIENT_ID" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=DMOAuthClientID)")
    "DM_OAUTH_CLIENT_SECRET" = format("%s%s%s", "@Microsoft.KeyVault(VaultName=", azurerm_key_vault.kv.name, ";SecretName=DMOAuthClientSecret)")
    "DM_INSPECTION_LOG_ENDPOINT" = format("%s%s", cloudfoundry_service_key.dmkey.credentials.public-api-endpoint, "/aiml/v1/inspectionLog")
    "PICTURE_STORAGE_ACCOUNT_ENDPOINT": azurerm_storage_account.sa.primary_blob_endpoint
    "AzureWebJobsStorageAccountExtension__serviceUri" = azurerm_storage_account.sa.primary_blob_endpoint
    "AzureWebJobsStorage__accountName" = local.storageAccountName
    "EventHubConnection__fullyQualifiedNamespace" = format("%s%s", azurerm_eventhub_namespace.eh.name, ".servicebus.windows.net")    
    "WEBSITE_RUN_FROM_PACKAGE" = format("%s%s", azurerm_storage_account.sa.primary_blob_endpoint, "deploy/dmext.zip")
  }
}

resource "azurerm_service_plan" "sp" {
  name                = local.appServicePlanName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = var.sp_sku
  
  tags = var.tags
}

resource "azurerm_windows_function_app" "fn" {
  name                = local.functionAppName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  public_network_access_enabled = false

  storage_account_name = azurerm_storage_account.sa.name
  storage_uses_managed_identity = true
  service_plan_id      = azurerm_service_plan.sp.id

  functions_extension_version = "~4"

  ftp_publish_basic_authentication_enabled = false
  
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_key = azurerm_application_insights.appinsights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.appinsights.connection_string    
    application_stack {
      dotnet_version = var.dotnet_version
    }
    always_on = true
  }

  app_settings = local.appsettings

  connection_string {
    name = "StorageAccountConnectionString"
    type  = "Custom"
    value = azurerm_storage_account.sa.primary_connection_string
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsStorage__accountName"],
      tags,
      virtual_network_subnet_id # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app#virtual_network_subnet_id
    ]
  }
}

# Function app VNet intergration
resource "azurerm_app_service_virtual_network_swift_connection" "network_integration" {
  app_service_id = azurerm_windows_function_app.fn.id
  subnet_id      = azurerm_subnet.extensionsubnet.id

  depends_on = [azurerm_subnet.extensionsubnet, azurerm_windows_function_app.fn]
}

resource "azurerm_monitor_diagnostic_setting" "diag_func" {
  name               = "${local.functionAppName}-diag"
  target_resource_id = azurerm_windows_function_app.fn.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ws.id

  metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [metric]
  }
}

data "azurerm_function_app_host_keys" "fnkeys" {
  name                = azurerm_windows_function_app.fn.name
  resource_group_name = azurerm_resource_group.rg.name
}

output "function_app_name" {
  value = azurerm_windows_function_app.fn.name
}