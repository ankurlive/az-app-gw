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

  # Option 2 is active: Service Principal authentication via variables.
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  # Example inline format (keep commented; do not commit secrets in code):
  # tenant_id       = "00000000-0000-0000-0000-000000000000"
  # subscription_id = "00000000-0000-0000-0000-000000000000"
  # client_id       = "00000000-0000-0000-0000-000000000000"
  # client_secret   = "your-client-secret"
}
