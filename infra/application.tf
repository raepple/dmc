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
  application_id = azuread_application.app.id
}

output "SAPDMExtensionAppSecret" {
  value = nonsensitive(azuread_application_password.appsecret.value)
}
