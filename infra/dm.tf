data "cloudfoundry_space" "cfspace" {
    name = var.btp_space
    org = var.btp_org
}

data "cloudfoundry_service" "destinationsrv" {
  name = var.destination_service_name
}

# Create destination

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
            clientId                 = "${azuread_application.app.client_id}"
            clientSecret             = "${azuread_application_password.appsecret.value}"
            tokenServiceURL          = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/v2.0/token"
            scope                    = "api://${local.applicationName}/.default"
          }
        ]
      }
    }
  })
}

data "cloudfoundry_service" "dmsrv" {
  name = var.dm_service_name
}

# Create Digitial Manufacturing service instance

resource "cloudfoundry_service_instance" "dmsi" {
  name         = local.dmServiceInstance
  space        = data.cloudfoundry_space.cfspace.id
  service_plan = data.cloudfoundry_service.dmsrv.service_plans["execution"]
}

# Create service key for DM service instance

resource "cloudfoundry_service_key" "dmkey" {
  name = local.dmServiceKey
  service_instance = cloudfoundry_service_instance.dmsi.id
}
