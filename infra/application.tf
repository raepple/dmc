resource "random_uuid" "app_scope_id" {}

# Create Azure AD App Registration for DM extension
resource "azuread_application" "app" {
  display_name = "DM Visual Inspection Extension"
  identifier_uris  = ["api://${local.appName}"]
  api {
    requested_access_token_version = 2
    oauth2_permission_scope {
      id                         = random_uuid.app_scope_id.result
      admin_consent_description  = "Access to DM Visual Inspection Extension"
      admin_consent_display_name = "DMExtension"
      enabled                    = true
      type                       = "User"
      value                      = "dmextvi.access"
    }
  }
}

resource "azuread_application_password" "appsecret" {
  application_object_id = azuread_application.app.object_id
}

output "DMExtension_app_URI" {
  description = "DM extension app uri"
  value       = azuread_application.app.identifier_uris
}

output "EntraID_client_id" {
  description = "DM extension client id"
  value       = azuread_application.app.application_id
}

output "EntraID_client_secret" {
  description = "DM extension client secret"
  value       = nonsensitive(azuread_application_password.appsecret.value)
}

output "EntraID_oauth_token_url" {
  description = "Entra ID tenant token url"
  value       = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/v2.0/token"
}