variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "dmext"
}

variable "resourceFunction" {
    description = "Function of the resources for the DM extension, e.g. visual inspection ('vi')" 
    type = string
}

variable "environment" {
  description = "Environment for all resources"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region for all resources"
  type        = string
  default     = "we"
}

variable "location" {
  description = "Location for all resources"
  type        = string
  default     = "westeurope"
}

variable "tags" {
    type = map
}

variable "publisher_email" {
  default     = "info@bestrun.com"
  description = "The email address of the owner of the APIM service"
  type        = string
  validation {
    condition     = length(var.publisher_email) > 0
    error_message = "The publisher_email must contain at least one character."
  }
}

variable "publisher_name" {
  description = "The name of the owner of the APIM service"
  type        = string
  validation {
    condition     = length(var.publisher_name) > 0
    error_message = "The publisher_name must contain at least one character."
  }
}

variable "apim_sku" {
  description = "The pricing tier of the APIM service"
  default     = "Developer_1"
  type        = string
}

variable "cs_sku" {
  description = "The pricing tier of the Cognitive Services"
  default     = "S0" 
  type        = string
}

variable "sp_sku" {
  description = "The pricing tier of the Service Plan"
  default     = "EP1" 
  type        = string
}

variable "eh_sku" {
  description = "EventHub SKU"
  type        = string
  default     = "Standard"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "apim_subnet_address_prefix" {
  description = "Address prefix for the APIM subnet"
  type        = list(string)
  default     = ["10.20.0.0/24"]
}

variable "extension_subnet_address_prefix" {
  description = "Address prefix for the extension components subnet"
  type        = list(string)
  default     = ["10.20.1.0/24"]
}

variable "btp_subaccount_id" {
  description = "Business Technology Platform subaccount id"
  type        = string
}

variable "btp_username" {
  description = "Business Technology Platform username"
  type        = string
}

variable "btp_password" {
  description = "Business Technology Platform password"
  type        = string
}

variable "cf_api_url" {
  description = "Cloud Foundry API URL"
  type        = string
}

variable "btp_space" {
  description = "BTP space name"
  type       = string
}

variable "btp_org" {
  description = "BTP org name"
  type      = string
}

variable "dm_aiml_api_endpoint" {
  description = "DM AI/ML log inspection endpoint"
  type        = string
}

variable "dm_service_name" {
  description = "DM service name"
  type        = string
}

variable "destination_service_name" {
  description = "Destination service name"
  type        = string
}