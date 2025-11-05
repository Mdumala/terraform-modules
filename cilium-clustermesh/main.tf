# ============================================================================
# CLUSTER 1 - ClusterMesh Configuration
# ============================================================================

# Włączenie ClusterMesh w Cilium dla klastra 1
resource "kubectl_manifest" "cluster1_cilium_config" {
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cilium-config
      namespace: ${local.cilium_namespace}
    data:
      cluster-name: ${local.cluster1_name}
      cluster-id: "${local.cluster1_id}"
      enable-clustermesh: "true"
      clustermesh-config: |
        enable-kvstoremesh: ${local.clustermesh_config.kv_store_mesh}
        enable-external-workloads: ${var.enable_external_workloads}
  YAML

  force_conflicts   = true
  server_side_apply = true
}

# Deployment ClusterMesh API Server dla klastra 1
resource "kubectl_manifest" "cluster1_clustermesh_apiserver" {
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
      labels:
        app.kubernetes.io/name: clustermesh-apiserver
        app.kubernetes.io/part-of: cilium
    spec:
      replicas: ${local.clustermesh_config.apiserver.replicas}
      selector:
        matchLabels:
          app.kubernetes.io/name: clustermesh-apiserver
      template:
        metadata:
          labels:
            app.kubernetes.io/name: clustermesh-apiserver
            app.kubernetes.io/part-of: cilium
        spec:
          serviceAccountName: clustermesh-apiserver
          containers:
          - name: apiserver
            image: quay.io/cilium/clustermesh-apiserver:latest
            imagePullPolicy: IfNotPresent
            command:
            - /usr/bin/clustermesh-apiserver
            args:
            - --cluster-name=${local.cluster1_name}
            - --cluster-id=${local.cluster1_id}
            env:
            - name: CILIUM_CLUSTER_NAME
              value: ${local.cluster1_name}
            - name: CILIUM_CLUSTER_ID
              value: "${local.cluster1_id}"
            ports:
            - name: api
              containerPort: 2379
              protocol: TCP
            - name: health
              containerPort: 9880
              protocol: TCP
            livenessProbe:
              httpGet:
                path: /healthz
                port: 9880
                scheme: HTTP
              initialDelaySeconds: 30
              periodSeconds: 10
            readinessProbe:
              httpGet:
                path: /readyz
                port: 9880
                scheme: HTTP
              initialDelaySeconds: 5
              periodSeconds: 5
  YAML

  depends_on = [kubectl_manifest.cluster1_cilium_config]
}

# Service dla ClusterMesh API Server klastra 1
resource "kubectl_manifest" "cluster1_clustermesh_service" {
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
      labels:
        app.kubernetes.io/name: clustermesh-apiserver
    spec:
      type: ${local.clustermesh_config.apiserver.service_type}
      selector:
        app.kubernetes.io/name: clustermesh-apiserver
      ports:
      - name: api
        port: 2379
        targetPort: 2379
        protocol: TCP
      - name: health
        port: 9880
        targetPort: 9880
        protocol: TCP
  YAML

  depends_on = [kubectl_manifest.cluster1_clustermesh_apiserver]
}

# ServiceAccount dla ClusterMesh API Server klastra 1
resource "kubectl_manifest" "cluster1_clustermesh_sa" {
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
  YAML
}

# ============================================================================
# CLUSTER 2 - ClusterMesh Configuration
# ============================================================================

# Włączenie ClusterMesh w Cilium dla klastra 2
resource "kubectl_manifest" "cluster2_cilium_config" {
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cilium-config
      namespace: ${local.cilium_namespace}
    data:
      cluster-name: ${local.cluster2_name}
      cluster-id: "${local.cluster2_id}"
      enable-clustermesh: "true"
      clustermesh-config: |
        enable-kvstoremesh: ${local.clustermesh_config.kv_store_mesh}
        enable-external-workloads: ${var.enable_external_workloads}
  YAML

  force_conflicts   = true
  server_side_apply = true
}

# Deployment ClusterMesh API Server dla klastra 2
resource "kubectl_manifest" "cluster2_clustermesh_apiserver" {
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
      labels:
        app.kubernetes.io/name: clustermesh-apiserver
        app.kubernetes.io/part-of: cilium
    spec:
      replicas: ${local.clustermesh_config.apiserver.replicas}
      selector:
        matchLabels:
          app.kubernetes.io/name: clustermesh-apiserver
      template:
        metadata:
          labels:
            app.kubernetes.io/name: clustermesh-apiserver
            app.kubernetes.io/part-of: cilium
        spec:
          serviceAccountName: clustermesh-apiserver
          containers:
          - name: apiserver
            image: quay.io/cilium/clustermesh-apiserver:latest
            imagePullPolicy: IfNotPresent
            command:
            - /usr/bin/clustermesh-apiserver
            args:
            - --cluster-name=${local.cluster2_name}
            - --cluster-id=${local.cluster2_id}
            env:
            - name: CILIUM_CLUSTER_NAME
              value: ${local.cluster2_name}
            - name: CILIUM_CLUSTER_ID
              value: "${local.cluster2_id}"
            ports:
            - name: api
              containerPort: 2379
              protocol: TCP
            - name: health
              containerPort: 9880
              protocol: TCP
            livenessProbe:
              httpGet:
                path: /healthz
                port: 9880
                scheme: HTTP
              initialDelaySeconds: 30
              periodSeconds: 10
            readinessProbe:
              httpGet:
                path: /readyz
                port: 9880
                scheme: HTTP
              initialDelaySeconds: 5
              periodSeconds: 5
  YAML

  depends_on = [kubectl_manifest.cluster2_cilium_config]
}

# Service dla ClusterMesh API Server klastra 2
resource "kubectl_manifest" "cluster2_clustermesh_service" {
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
      labels:
        app.kubernetes.io/name: clustermesh-apiserver
    spec:
      type: ${local.clustermesh_config.apiserver.service_type}
      selector:
        app.kubernetes.io/name: clustermesh-apiserver
      ports:
      - name: api
        port: 2379
        targetPort: 2379
        protocol: TCP
      - name: health
        port: 9880
        targetPort: 9880
        protocol: TCP
  YAML

  depends_on = [kubectl_manifest.cluster2_clustermesh_apiserver]
}

# ServiceAccount dla ClusterMesh API Server klastra 2
resource "kubectl_manifest" "cluster2_clustermesh_sa" {
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: clustermesh-apiserver
      namespace: ${local.cilium_namespace}
  YAML
}

# ============================================================================
# CLUSTER MESH PEERING - Połączenie klastrów
# ============================================================================

# Secret w klastrze 1 z informacjami o klastrze 2
resource "kubectl_manifest" "cluster1_remote_cluster2_secret" {
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: cilium-clustermesh-${local.cluster2_name}
      namespace: ${local.cilium_namespace}
      labels:
        io.cilium/cluster-mesh: "true"
    type: Opaque
    stringData:
      cluster-name: ${local.cluster2_name}
      cluster-id: "${local.cluster2_id}"
      mesh-endpoint: ${local.cluster2_mesh_endpoint}
  YAML

  depends_on = [
    kubectl_manifest.cluster1_clustermesh_apiserver,
    kubectl_manifest.cluster2_clustermesh_apiserver
  ]
}

# Secret w klastrze 2 z informacjami o klastrze 1
resource "kubectl_manifest" "cluster2_remote_cluster1_secret" {
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: cilium-clustermesh-${local.cluster1_name}
      namespace: ${local.cilium_namespace}
      labels:
        io.cilium/cluster-mesh: "true"
    type: Opaque
    stringData:
      cluster-name: ${local.cluster1_name}
      cluster-id: "${local.cluster1_id}"
      mesh-endpoint: ${local.cluster1_mesh_endpoint}
  YAML

  depends_on = [
    kubectl_manifest.cluster1_clustermesh_apiserver,
    kubectl_manifest.cluster2_clustermesh_apiserver
  ]
}

# ============================================================================
# CONNECTIVITY VALIDATION (opcjonalne)
# ============================================================================

# Test connectivity - Job w klastrze 1 sprawdzający dostęp do klastra 2
resource "kubectl_manifest" "cluster1_connectivity_test" {
  count    = var.wait_for_connectivity ? 1 : 0
  provider = kubectl.cluster1

  yaml_body = <<-YAML
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: clustermesh-connectivity-test
      namespace: ${local.cilium_namespace}
    spec:
      template:
        metadata:
          labels:
            app: clustermesh-connectivity-test
        spec:
          restartPolicy: OnFailure
          containers:
          - name: connectivity-test
            image: quay.io/cilium/cilium:latest
            command:
            - /bin/sh
            - -c
            - |
              echo "Testing connectivity to cluster ${local.cluster2_name}..."
              cilium clustermesh status
              cilium clustermesh vm status || true
              echo "Connectivity test completed"
            env:
            - name: CILIUM_CLUSTER_NAME
              value: ${local.cluster1_name}
      backoffLimit: 3
  YAML

  depends_on = [
    kubectl_manifest.cluster1_remote_cluster2_secret,
    kubectl_manifest.cluster2_remote_cluster1_secret
  ]
}

# Test connectivity - Job w klastrze 2 sprawdzający dostęp do klastra 1
resource "kubectl_manifest" "cluster2_connectivity_test" {
  count    = var.wait_for_connectivity ? 1 : 0
  provider = kubectl.cluster2

  yaml_body = <<-YAML
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: clustermesh-connectivity-test
      namespace: ${local.cilium_namespace}
    spec:
      template:
        metadata:
          labels:
            app: clustermesh-connectivity-test
        spec:
          restartPolicy: OnFailure
          containers:
          - name: connectivity-test
            image: quay.io/cilium/cilium:latest
            command:
            - /bin/sh
            - -c
            - |
              echo "Testing connectivity to cluster ${local.cluster1_name}..."
              cilium clustermesh status
              cilium clustermesh vm status || true
              echo "Connectivity test completed"
            env:
            - name: CILIUM_CLUSTER_NAME
              value: ${local.cluster2_name}
      backoffLimit: 3
  YAML

  depends_on = [
    kubectl_manifest.cluster1_remote_cluster2_secret,
    kubectl_manifest.cluster2_remote_cluster1_secret
  ]
}
