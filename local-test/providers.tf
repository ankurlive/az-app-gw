terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Option 2 is active: Service Principal authentication via locals in main.tf.
  tenant_id       = local.tenant_id
  subscription_id = local.subscription_id
  client_id       = local.client_id
  client_secret   = local.client_secret
}
