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

  depends_on = [ azurerm_subnet_network_security_group_association.apimsubnetNsg ]
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
  url                 = "https://${azurerm_windows_function_app.fn.default_hostname}/api"
}

resource "azurerm_api_management_named_value" "apimnv" {
  name                = "${azurerm_windows_function_app.fn.name}-key"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "${azurerm_windows_function_app.fn.name}-key"
  secret              = true
  value_from_key_vault  {
    secret_id = azurerm_key_vault_secret.kvsecrets["FunctionAppHostKey"].id
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
          <set-backend-service backend-id="${azurerm_api_management_backend.apimbackend.name}" />
          <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Invalid token">
            <openid-config url="https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>${azuread_application.app.client_id}</audience>
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
