# Output ID klastra w formacie v2
output "cluster_id" {
  description = "ID utworzonego klastra Rancher (format v2)"
  value       = rancher2_cluster_v2.cluster.id
}

# Output ID klastra w formacie v1 (dla kompatybilności)
output "cluster_id_v1" {
  description = "ID v1 utworzonego klastra Rancher"
  value       = rancher2_cluster_v2.cluster.cluster_v1_id
}

# Output nazwy klastra
output "cluster_name" {
  description = "Nazwa utworzonego klastra"
  value       = rancher2_cluster_v2.cluster.name
}

# Output informacji o Azure location
output "azure_location" {
  description = "Azure region gdzie utworzono klaster"
  value       = var.azure_location
}

# Output Resource Group
output "azure_resource_group" {
  description = "Azure Resource Group"
  value       = var.azure_resource_group
}

# Output debug info
output "cluster_ids_debug" {
  description = "Wszystkie identyfikatory klastra dla debugowania"
  value = {
    cluster_id         = rancher2_cluster_v2.cluster.id
    cluster_v1_id      = rancher2_cluster_v2.cluster.cluster_v1_id
    cluster_name       = rancher2_cluster_v2.cluster.name
    kubernetes_version = rancher2_cluster_v2.cluster.kubernetes_version
  }
}
