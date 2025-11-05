# Konfiguracja ClusterMesh
locals {
  # Nazwy klastrów
  cluster1_name = var.cluster1_name
  cluster2_name = var.cluster2_name

  # Cluster IDs
  cluster1_id = var.cluster1_id
  cluster2_id = var.cluster2_id

  # Namespace Cilium
  cilium_namespace = var.cilium_namespace

  # ClusterMesh configuration
  clustermesh_config = {
    apiserver = {
      service_type = var.clustermesh_apiserver_service_type
      replicas     = var.clustermesh_apiserver_replicas
    }
    kv_store_mesh = var.enable_kv_store_mesh
  }

  # Mesh endpoints
  cluster1_mesh_endpoint = var.cluster1_mesh_endpoint
  cluster2_mesh_endpoint = var.cluster2_mesh_endpoint
}
