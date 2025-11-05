terraform {
  required_providers {
    vsphere = {
      source  = "opentofu/vsphere"
      version = "2.12.0"
    }
    rancher2 = {
      source  = "opentofu/rancher2"
      version = "13.0.0-rc1"
    }
  }
}