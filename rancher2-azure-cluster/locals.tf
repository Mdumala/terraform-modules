# Mapowanie aliasu cloud providera na ID credentials
locals {
  cloud_credential_id = data.rancher2_cloud_credential.azure.id

  # CIDRy sieci
  cluster_cidr = var.cluster_cidr
  service_cidr = var.service_cidr

  # CIS profile
  profile_cis = var.profile_cis
}
