locals {
  service_cidr = var.service_cidr
  cluster_cidr = var.cluster_cidr
  profile_cis  = var.profile_cis
}


locals {
  cloud_credentials_map = {
    SDC = data.rancher2_cloud_credential.sdc.id
    PDC = data.rancher2_cloud_credential.pdc.id
  }
  selected_credential_id = local.cloud_credentials_map[var.cloud_provider]

}