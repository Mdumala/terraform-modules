terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "opentofu/helm"
      version = "~> 2.16"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Provider dla klastra 1 (np. vSphere)
provider "kubernetes" {
  alias = "cluster1"

  host                   = var.cluster1_host
  token                  = var.cluster1_token
  cluster_ca_certificate = var.cluster1_ca_cert
}

provider "helm" {
  alias = "cluster1"

  kubernetes {
    host                   = var.cluster1_host
    token                  = var.cluster1_token
    cluster_ca_certificate = var.cluster1_ca_cert
  }
}

provider "kubectl" {
  alias = "cluster1"

  host                   = var.cluster1_host
  token                  = var.cluster1_token
  cluster_ca_certificate = var.cluster1_ca_cert
  load_config_file       = false
}

# Provider dla klastra 2 (np. Azure)
provider "kubernetes" {
  alias = "cluster2"

  host                   = var.cluster2_host
  token                  = var.cluster2_token
  cluster_ca_certificate = var.cluster2_ca_cert
}

provider "helm" {
  alias = "cluster2"

  kubernetes {
    host                   = var.cluster2_host
    token                  = var.cluster2_token
    cluster_ca_certificate = var.cluster2_ca_cert
  }
}

provider "kubectl" {
  alias = "cluster2"

  host                   = var.cluster2_host
  token                  = var.cluster2_token
  cluster_ca_certificate = var.cluster2_ca_cert
  load_config_file       = false
}
