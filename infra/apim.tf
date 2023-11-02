resource "azurerm_api_management" "apim" {
  name                = local.apimName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  sku_name = var.apim_sku

  public_ip_address_id = azurerm_public_ip.pip.id

  identity {
    type = "SystemAssigned"
  }

  virtual_network_type = "External"

  virtual_network_configuration {
      subnet_id = azurerm_subnet.apimsubnet.id
  }

  tags = var.tags
}

resource "azurerm_api_management_api" "apimapi" {
  name                = local.apiName
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = local.apiName
  path                = local.apiPath
  protocols           = ["https"]
  subscription_required = false
}

resource "azurerm_api_management_backend" "apimbackend" {
  name                = local.functionAppName
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = "https://${azurerm_windows_function_app.fn.name}.azurewebsites.net/api/"
}

resource "azurerm_api_management_named_value" "apimnv" {
  name                = "${azurerm_windows_function_app.fn.name}-key"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "${azurerm_windows_function_app.fn.name}-key"
  secret              = true
  value_from_key_vault  {
    secret_id = data.azurerm_key_vault_secret.fnhk.id
  }
}

resource "azurerm_api_management_api_policy" "apimBasePolicy" {
  api_name            = azurerm_api_management_api.apimapi.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
  <policies>
      <inbound>
          <base />
          <set-backend-service id="apim-generated-policy" backend-id="${azurerm_api_management_backend.apimbackend.name}" />
          <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Invalid token">
            <openid-config url="https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>${azuread_application.app.application_id}</audience>
            </audiences>
          </validate-jwt>
          <set-query-parameter name="code" exists-action="override">
            <value>{{${azurerm_api_management_named_value.apimnv.name}}}</value>
          </set-query-parameter>
      </inbound>
      <backend>
          <base />
      </backend>
      <outbound>
          <base />
      </outbound>
      <on-error>
          <base />
      </on-error>
  </policies>
XML
}

# APIM operations
resource "azurerm_api_management_api_operation" "apimtprop" {
  operation_id        = "TakePictureRequestBase64"
  api_name            = azurerm_api_management_api.apimapi.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "TakePictureRequestBase64"
  method              = "GET"
  url_template        = "/TakePictureRequestBase64"
  description         = "Take camera picture and return base64 encoded image"
  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "apimrpaop" {
  operation_id        = "RequestPictureAnalysis"
  api_name            = azurerm_api_management_api.apimapi.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "RequestPictureAnalysis"
  method              = "POST"
  url_template        = "/RequestPictureAnalysis"
  description         = "Send a camera picture to the visual inspection extension service for analysis"
  response {
    status_code = 200
  }
}

# Create a logger to send logs to Application Insights
resource "azurerm_api_management_logger" "apimlogger" {
  name                = "apimlogger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appinsights.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appinsights.instrumentation_key
  }
}

# Create a diagnostic setting to send logs to Application Insights
resource "azurerm_api_management_api_diagnostic" "apimdiag" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azurerm_api_management.apim.name
  api_name                 = azurerm_api_management_api.apimapi.name
  api_management_logger_id = azurerm_api_management_logger.apimlogger.id

  sampling_percentage       = 5.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}

