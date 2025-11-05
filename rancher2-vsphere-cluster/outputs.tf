###############
# Outputs - (opcjonalne) zmienne wyjściowe modułu
###############
output "cluster_id" {
  description = "ID utworzonego klastra Rancher"
  value       = rancher2_cluster_v2.cluster.id
}
output "cluster_id_v1" {
  description = "ID v1 utworzonego klastra Rancher"
  value       = rancher2_cluster_v2.cluster.cluster_v1_id
}
output "cluster_name" {
  description = "Nazwa utworzonego klastra"
  value       = rancher2_cluster_v2.cluster.name
}

output "cluster_ids_debug" {
  value = {
    cluster_id    = rancher2_cluster_v2.cluster.id # powinno wyglądać jak c-m-xxxx
    cluster_v1_id = rancher2_cluster_v2.cluster.cluster_v1_id
    cluster_name  = rancher2_cluster_v2.cluster.name
  }
}