terraform {
  required_providers {
    azurerm = {
      source  = "opentofu/azurerm"
      version = "~> 4.0"
    }
    rancher2 = {
      source  = "opentofu/rancher2"
      version = "13.0.0-rc1"
    }
  }
}
