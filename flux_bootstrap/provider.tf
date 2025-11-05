terraform {
  required_providers {
    gitlab = {
      source  = "opentofu/gitlab"
      version = "17.1.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.6.4"
    }
  }
}