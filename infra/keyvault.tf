resource "azurerm_key_vault" "kv" {
  name                        = local.kvName
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  sku_name = "standard"

  network_acls {
    // NOTE: Terraform does not allow for Key Vault network ACL to be set independently of Key Vault
    //       resource creation. As such, after the Key Vault resource is created, when network ACLs are set for
    //       "Bypass = None" and "Default_Action = Deny", Key Vault
    //       secrets cannot be set via Terraform.
    //       
    //       Please see discussion at https://github.com/terraform-providers/terraform-provider-azurerm/issues/3130
    default_action  = "Deny"
    bypass          = "AzureServices"
    ip_rules        = var.white_list_ip
  }
  tags = var.tags
}

locals {
  kvsecrets = {
    "CustomVisionKey" = azurerm_cognitive_account.cs.primary_access_key
    "DMOAuthClientID" = cloudfoundry_service_key.dmkey.credentials.uaa_clientid
    "DMOAuthClientSecret" = cloudfoundry_service_key.dmkey.credentials.uaa_clientsecret
    "FunctionAppHostKey" = data.azurerm_function_app_host_keys.fnkeys.default_function_key
    "StorageAccountConnectionString" = azurerm_storage_account.sa.primary_connection_string
  }
}

resource "azurerm_key_vault_secret" "kvsecrets" {
  for_each     = local.kvsecrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
}

# needed for reference in API management
data "azurerm_key_vault_secret" "fnhk" {
  name         = "FunctionAppHostKey"
  key_vault_id = azurerm_key_vault.kv.id
}