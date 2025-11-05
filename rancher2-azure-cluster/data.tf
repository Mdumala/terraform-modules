# Pobieranie istniejących Cloud Credentials z Rancher dla Azure
data "rancher2_cloud_credential" "azure" {
  name = "Azure"
}
