resource "azurerm_virtual_network" "vnet" {
  name                = local.vnetName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  # use Azure DNS server
  dns_servers         = ["168.63.129.16"]

  tags = var.tags
}

resource "azurerm_subnet" "apimsubnet" {
  name                 = "APIMSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.apim_subnet_address_prefix
}

resource "azurerm_subnet" "extensionsubnet" {
  name                 = "ExtensionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.extension_subnet_address_prefix
 
  delegation {
    name = "serverFarms"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "pepsubnet" {
  name                 = "PEPSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.pep_subnet_address_prefix
  private_endpoint_network_policies_enabled = true
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Web",
  ]  
}

resource "azurerm_network_security_group" "nsgapim" {
  name                = local.nsgNameAPIM
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  security_rule {
    access                     = "Allow"
    destination_address_prefix = azurerm_subnet.apimsubnet.address_prefixes[0]
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowInetHttpsInbound"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "3443"
    direction                  = "Inbound"
    name                       = "AllowApiManagementInbound"
    priority                   = 110
    protocol                   = "Tcp"
    source_address_prefix      = "ApiManagement"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = azurerm_subnet.apimsubnet.address_prefixes[0]
    destination_port_range     = "6390"
    direction                  = "Inbound"
    name                       = "AllowAzureLBInbound"
    priority                   = 120
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "apimsubnetNsg" {
  subnet_id                 = azurerm_subnet.apimsubnet.id
  network_security_group_id = azurerm_network_security_group.nsgapim.id
}
