data "btp_subaccount" "btpsubaccount" {
  id = var.btp_subaccount_id
}

data "cloudfoundry_space" "cfspace" {
    name = var.btp_space
    org = var.btp_org
}

data "cloudfoundry_service" "destinationsrv" {
  name = var.destination_service_name
}

resource "cloudfoundry_service_instance" "destinationsi" {
  name         = local.destinationServiceInstance
  space        = data.cloudfoundry_space.cfspace.id
  service_plan = data.cloudfoundry_service.destinationsrv.service_plans["lite"]
  json_params = jsonencode({    
    init_data = {
      subaccount = {
        existing_destinations_policy = "update"
        destinations = [
          {
            Name                     = "${local.destinationName}"
            Type                     = "HTTP"
            Description              = "Endpoint to DM extension"
            URL                      = "${azurerm_api_management.apim.gateway_url}"
            ProxyType                = "Internet"
            Authentication           = "OAuth2ClientCredentials"
            clientId                 = "${azuread_application.app.application_id}"
            clientSecret             = "${azuread_application_password.appsecret.value}"
            tokenServiceURL          = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/v2.0/token"
            scope                    = "api://${local.appName}/.default"
          }
        ]
      }
    }
  })
}

resource "btp_subaccount_entitlement" "destination" {
  subaccount_id = data.btp_subaccount.btpsubaccount.id
  service_name  = "destination"
  plan_name     = "lite"
}

resource "btp_subaccount_service_instance" "destination" {
  subaccount_id  = data.btp_subaccount.btpsubaccount.id
  serviceplan_id = data.cloudfoundry_service.destinationsrv.service_plans["lite"]
  depends_on     = [btp_subaccount_entitlement.destination]
  name           = "TestDestinationSrvInstance"
  parameters = jsonencode({    
    init_data = {
      subaccount = {
        existing_destinations_policy = "update"
        destinations = [
          {
            Name                     = "TestDestination"
            Type                     = "HTTP"
            Description              = "Endpoint to DM extension"
            URL                      = "${azurerm_api_management.apim.gateway_url}"
            ProxyType                = "Internet"
            Authentication           = "OAuth2ClientCredentials"
            clientId                 = "${azuread_application.app.application_id}"
            clientSecret             = "${azuread_application_password.appsecret.value}"
            tokenServiceURL          = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/v2.0/token"
            scope                    = "api://${local.appName}/.default"
          }
        ]
      }
    }
  })
}

data "cloudfoundry_service" "dmsrv" {
  name = var.dm_service_name
}

resource "cloudfoundry_service_instance" "dmsi" {
  name         = local.dmServiceInstance
  space        = data.cloudfoundry_space.cfspace.id
  service_plan = data.cloudfoundry_service.dmsrv.service_plans["execution"]
}

output "dm_service_plan" {
  description = "DM service plan for execution"
  value       = data.cloudfoundry_service.dmsrv.service_plans["execution"]
}

resource "cloudfoundry_service_key" "dmkey" {
  name = local.dmServiceKey
  service_instance = cloudfoundry_service_instance.dmsi.id
}

output "dmsrv_key_clientid" {
  description = "DM service key client id"
  value       = nonsensitive(cloudfoundry_service_key.dmkey.credentials.uaa_clientid)
}

output "dmsrv_key_clientsecret" {
  description = "DM service key client secret"
  value       = nonsensitive(cloudfoundry_service_key.dmkey.credentials.uaa_clientsecret)
}

output "dmsrv_key_tokenurl" {
  description = "XSUAA token endpoint url"
  value       = nonsensitive(cloudfoundry_service_key.dmkey.credentials.uaa_url)
}