## Cluster 1 Configuration (np. vSphere) ##
variable "cluster1_name" {
  description = "Nazwa pierwszego klastra (dla identyfikacji w mesh)"
  type        = string
}

variable "cluster1_host" {
  description = "Kubernetes API endpoint dla klastra 1"
  type        = string
}

variable "cluster1_token" {
  description = "Token dostępowy do klastra 1"
  type        = string
  sensitive   = true
}

variable "cluster1_ca_cert" {
  description = "CA certificate klastra 1 (base64 decoded)"
  type        = string
  sensitive   = true
}

variable "cluster1_id" {
  description = "Unikalny ID klastra 1 (1-255)"
  type        = number
  default     = 1

  validation {
    condition     = var.cluster1_id >= 1 && var.cluster1_id <= 255
    error_message = "Cluster ID musi być między 1 a 255"
  }
}

## Cluster 2 Configuration (np. Azure) ##
variable "cluster2_name" {
  description = "Nazwa drugiego klastra (dla identyfikacji w mesh)"
  type        = string
}

variable "cluster2_host" {
  description = "Kubernetes API endpoint dla klastra 2"
  type        = string
}

variable "cluster2_token" {
  description = "Token dostępowy do klastra 2"
  type        = string
  sensitive   = true
}

variable "cluster2_ca_cert" {
  description = "CA certificate klastra 2 (base64 decoded)"
  type        = string
  sensitive   = true
}

variable "cluster2_id" {
  description = "Unikalny ID klastra 2 (1-255)"
  type        = number
  default     = 2

  validation {
    condition     = var.cluster2_id >= 1 && var.cluster2_id <= 255
    error_message = "Cluster ID musi być między 1 a 255"
  }
}

## ClusterMesh Configuration ##
variable "clustermesh_apiserver_service_type" {
  description = "Typ Service dla ClusterMesh API Server (LoadBalancer, NodePort, ClusterIP)"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.clustermesh_apiserver_service_type)
    error_message = "Service type musi być: LoadBalancer, NodePort, lub ClusterIP"
  }
}

variable "clustermesh_apiserver_replicas" {
  description = "Liczba replik ClusterMesh API Server"
  type        = number
  default     = 1
}

variable "enable_kv_store_mesh" {
  description = "Włącz KV store mesh (etcd synchronization)"
  type        = bool
  default     = true
}

variable "wait_for_connectivity" {
  description = "Czekaj na weryfikację connectivity między klastrami"
  type        = bool
  default     = true
}

## Network Configuration ##
variable "cluster1_mesh_endpoint" {
  description = "Endpoint dla ClusterMesh API Server klastra 1 (IP:port dostępny z klastra 2 przez VPN)"
  type        = string
}

variable "cluster2_mesh_endpoint" {
  description = "Endpoint dla ClusterMesh API Server klastra 2 (IP:port dostępny z klastra 1 przez VPN)"
  type        = string
}

## Optional ##
variable "cilium_namespace" {
  description = "Namespace gdzie jest zainstalowany Cilium"
  type        = string
  default     = "kube-system"
}

variable "enable_external_workloads" {
  description = "Włącz wsparcie dla external workloads (VM spoza klastra)"
  type        = bool
  default     = false
}
