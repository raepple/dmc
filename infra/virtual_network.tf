resource "azurerm_virtual_network" "vnet" {
  name                = local.vnetName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_network_security_group" "apimnsg" {
  name                = local.nsgapimName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["443"]
    direction                  = "Inbound"
    name                       = "AllowInetHttpsToAPIMInbound"
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
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "6390"
    direction                  = "Inbound"
    name                       = "AllowAzureInfraLoadBalancerInbound"
    priority                   = 120
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "Storage"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "DependencyOnAzureStorageOutbound"
    priority                   = 130
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "Sql"
    destination_port_range     = "1433"
    direction                  = "Outbound"
    name                       = "AllowAzureSQLOutbound"
    priority                   = 140
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "AzureKeyVault"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "AccessToAzureKeyVaultOutbound"
    priority                   = 150
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
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
}

resource "azurerm_subnet_network_security_group_association" "apimsubnetNsg" {
  subnet_id                 = azurerm_subnet.apimsubnet.id
  network_security_group_id = azurerm_network_security_group.apimnsg.id
}