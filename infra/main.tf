# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.43.0"
    }
    btp = {
      source  = "SAP/btp"
      version = "0.5.0-beta1"
    }    
    cloudfoundry = {
      source = "cloudfoundry-community/cloudfoundry"
      version = "0.51.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {
}

provider "btp" {
  globalaccount = "b54a9da4-05f1-4608-b5f3-0f2d9962db5f"
  username = var.btp_username
  password = var.btp_password
}

provider "cloudfoundry" {
  api_url = var.cf_api_url
  user = var.btp_username
  password = var.btp_password
}

# Constructed names of resources
locals {
  resourceGroupName   = "${var.prefix}-${var.resourceFunction}-rg-${var.environment}-${var.region}"
  storageAccountName  = "${var.prefix}${var.resourceFunction}sa${var.environment}${var.region}"  
  apimName            = "${var.prefix}-${var.resourceFunction}-apim-${var.environment}-${var.region}"
  apiName             = "${var.prefix}-${var.resourceFunction}-api"
  apiPath             = "${var.resourceFunction}"
  appName             = "${var.prefix}-${var.resourceFunction}"
  kvName              = "${var.prefix}-${var.resourceFunction}-kv-${var.environment}-${var.region}"
  eventHubName        = "${var.prefix}-${var.resourceFunction}-eh-${var.environment}-${var.region}"
  appServicePlanName  = "${var.prefix}-${var.resourceFunction}-sp-${var.environment}-${var.region}"  
  functionAppName     = "${var.prefix}-${var.resourceFunction}-fn-${var.environment}-${var.region}"
  workspaceName       = "${var.prefix}-${var.resourceFunction}-ws-${var.environment}-${var.region}"
  appinsightsName     = "${var.prefix}-${var.resourceFunction}-ai-${var.environment}-${var.region}"
  csName              = "${var.prefix}-${var.resourceFunction}-cs-${var.environment}-${var.region}"
  applicationName     = "${var.prefix}-${var.resourceFunction}-app-${var.environment}-${var.region}"
  pipName             = "${var.prefix}-${var.resourceFunction}-pip-${var.environment}-${var.region}"
  vnetName            = "${var.prefix}-${var.resourceFunction}-vnet-${var.environment}-${var.region}"
  nsgapimName         = "${var.prefix}-${var.resourceFunction}-nsgapim-${var.environment}-${var.region}"
  nsgextName          = "${var.prefix}-${var.resourceFunction}-nsgext-${var.environment}-${var.region}"
  csSubDomain         = "${var.prefix}${var.resourceFunction}cs"
  pipSubDomain        = "${var.prefix}${var.resourceFunction}"
  dmServiceInstance   = "${var.prefix}-${var.resourceFunction}-dm-${var.environment}-${var.region}"
  dmServiceKey        = "${var.prefix}-${var.resourceFunction}-dm-${var.environment}-${var.region}-key"
  destinationServiceInstance = "${var.prefix}-${var.resourceFunction}-destination-${var.environment}-${var.region}"
  destinationName     = "${var.prefix}-${var.resourceFunction}-destination-${var.environment}-${var.region}"
}

data "azurerm_client_config" "current" {}
