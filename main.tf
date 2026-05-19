resource "azurerm_resource_group" "rg" {
  name     = "rg-appgw-tcp"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# TCP-enabled Application Gateway (via AzAPI)
resource "azapi_resource" "appgw" {
  type      = "Microsoft.Network/applicationGateways@2023-09-01"
  name      = "appgw-tcp"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  body = {
    properties = {
      sku = {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        capacity = 1
      }

      gatewayIPConfigurations = [
        {
          name = "gw-ip-config"
          properties = {
            subnet = {
              id = azurerm_subnet.appgw.id
            }
          }
        }
      ]

      frontendIPConfigurations = [
        {
          name = "frontend-ip"
          properties = {
            publicIPAddress = {
              id = azurerm_public_ip.pip.id
            }
          }
        }
      ]

      frontendPorts = [
        {
          name = "tcp-port"
        }
      ]

      backendSettingsCollection = [
        {
          name = "tcp-settings"
          properties = {
            port     = 1433
            protocol = "Tcp"
            timeout  = 30
          }
        }
      ]

      listeners = [
        {
          name = "tcp-listener"
          properties = {
            frontendIPConfiguration = {
              id = "[concat(resourceId('Microsoft.Network/applicationGateways','appgw-tcp'), '/frontendIPConfigurations/frontend-ip')]"
            }
            frontendPort = {
              id = "[concat(resourceId('Microsoft.Network/applicationGateways','appgw-tcp'), '/frontendPorts/tcp-port')]"
            }
            protocol = "Tcp"
          }
        }
      ]

      routingRules = [
        {
          name = "tcp-rule"
          properties = {
            ruleType = "Basic"
            priority = 100
            listener = {
              id = "[concat(resourceId('Microsoft.Network/applicationGateways','appgw-tcp'), '/listeners/tcp-listener')]"
            }
            backendAddressPool = {
              id = "[concat(resourceId('Microsoft.Network/applicationGateways','appgw-tcp'), '/backendAddressPools/backend-pool')]"
            }
            backendSettings = {
              id = "[concat(resourceId('Microsoft.Network/applicationGateways','appgw-tcp'), '/backendSettingsCollection/tcp-settings')]"
            }
          }
        }
      ]
    }
  }
}
