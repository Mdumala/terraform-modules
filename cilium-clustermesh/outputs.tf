# Informacje o konfiguracji ClusterMesh
output "clustermesh_enabled" {
  description = "Status włączenia ClusterMesh"
  value       = true
}

# Cluster 1 info
output "cluster1_info" {
  description = "Informacje o klastrze 1"
  value = {
    name          = local.cluster1_name
    id            = local.cluster1_id
    mesh_endpoint = local.cluster1_mesh_endpoint
  }
}

# Cluster 2 info
output "cluster2_info" {
  description = "Informacje o klastrze 2"
  value = {
    name          = local.cluster2_name
    id            = local.cluster2_id
    mesh_endpoint = local.cluster2_mesh_endpoint
  }
}

# ClusterMesh configuration
output "clustermesh_config" {
  description = "Konfiguracja ClusterMesh"
  value = {
    service_type         = local.clustermesh_config.apiserver.service_type
    replicas             = local.clustermesh_config.apiserver.replicas
    kv_store_mesh        = local.clustermesh_config.kv_store_mesh
    external_workloads   = var.enable_external_workloads
  }
}

# Namespace
output "cilium_namespace" {
  description = "Namespace Cilium"
  value       = local.cilium_namespace
}

# Instrukcje weryfikacji
output "verification_commands" {
  description = "Komendy do weryfikacji ClusterMesh"
  value = {
    cluster1 = "kubectl --context=cluster1 -n ${local.cilium_namespace} exec -ti ds/cilium -- cilium clustermesh status"
    cluster2 = "kubectl --context=cluster2 -n ${local.cilium_namespace} exec -ti ds/cilium -- cilium clustermesh status"
    connectivity_test = "kubectl --context=cluster1 run -it --rm test-pod --image=busybox --restart=Never -- wget -O- http://<service>.${local.cluster2_name}.svc.clusterset.local"
  }
}

# Mesh peering status
output "mesh_peering" {
  description = "Status połączenia między klastrami"
  value = {
    cluster1_connects_to = local.cluster2_name
    cluster2_connects_to = local.cluster1_name
    connection_type      = "Full Mesh"
    communication        = "VPN Site-to-Site"
  }
}
