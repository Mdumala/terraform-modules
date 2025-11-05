# Moduł Terraform: cilium-clustermesh

Moduł do konfiguracji Cilium ClusterMesh - łączenia wielu klastrów Kubernetes w jedną sieć (Full Mesh).

## Opis

Ten moduł Terraform umożliwia:
- Automatyczną konfigurację Cilium ClusterMesh między dwoma klastrami Kubernetes
- **Full Mesh connectivity** - wszystkie pody w obu klastrach mogą się komunikować
- Global Service Discovery - Services dostępne między klastrami
- Synchronizację etcd między klastrami (KV Store Mesh)
- Komunikację przez VPN Site-to-Site (prywatne IP)
- Weryfikację connectivity po konfiguracji

## Architektura

```
┌──────────────────────────────────────────┐
│ Klaster 1 (np. vSphere)                  │
│ Cluster ID: 1                            │
│ Pod CIDR: 10.45.0.0/16                   │
│ Service CIDR: 10.46.0.0/16               │
│                                           │
│ ┌──────────────────────────────────┐    │
│ │ ClusterMesh API Server           │    │
│ │ (Deployment + Service)           │    │
│ │ Port: 2379                       │    │
│ └────────────┬─────────────────────┘    │
│              │                           │
│ ┌────────────▼─────────────────────┐    │
│ │ Cilium Agents                    │    │
│ │ - Routing do Cluster 2           │    │
│ │ - Service Discovery              │    │
│ └──────────────────────────────────┘    │
└──────────────┬───────────────────────────┘
               │
          VPN Site-to-Site
       (Prywatne IP, Bezpieczne)
               │
┌──────────────▼───────────────────────────┐
│ ┌──────────────────────────────────┐    │
│ │ Cilium Agents                    │    │
│ │ - Routing do Cluster 1           │    │
│ │ - Service Discovery              │    │
│ └────────────┬─────────────────────┘    │
│              │                           │
│ ┌────────────▼─────────────────────┐    │
│ │ ClusterMesh API Server           │    │
│ │ (Deployment + Service)           │    │
│ │ Port: 2379                       │    │
│ └──────────────────────────────────┘    │
│                                           │
│ Klaster 2 (np. Azure)                    │
│ Cluster ID: 2                            │
│ Pod CIDR: 10.47.0.0/16                   │
│ Service CIDR: 10.48.0.0/16               │
└──────────────────────────────────────────┘
```

## Wymagania

- OpenTofu >= v8.x
- Cilium CNI zainstalowany w obu klastrach (moduły `rancher2-vsphere-cluster` i `rancher2-azure-cluster` już to zapewniają)
- **VPN Site-to-Site** między klastrami (klastry muszą mieć connectivity na poziomie sieci)
- Token i CA cert dla dostępu do Kubernetes API obu klastrów
- **Unikalne Cluster IDs** (1-255) dla każdego klastra
- **Non-overlapping CIDRs** - sieci pod i service nie mogą nachodzić

## Providers

| Provider | Version | Źródło |
|----------|---------|--------|
| kubernetes | ~> 2.35 | opentofu/kubernetes |
| helm | ~> 2.16 | opentofu/helm |
| kubectl | ~> 1.14 | gavinbunney/kubectl |

## Zmienne wejściowe

### Cluster 1 (np. vSphere)
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `cluster1_name` | `string` | Nazwa klastra 1 | (wymagane) |
| `cluster1_host` | `string` | Kubernetes API endpoint | (wymagane) |
| `cluster1_token` | `string` | Token dostępowy | (wymagane, sensitive) |
| `cluster1_ca_cert` | `string` | CA certificate (base64 decoded) | (wymagane, sensitive) |
| `cluster1_id` | `number` | Cluster ID (1-255) | `1` |
| `cluster1_mesh_endpoint` | `string` | Mesh endpoint (IP:port) przez VPN | (wymagane) |

### Cluster 2 (np. Azure)
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `cluster2_name` | `string` | Nazwa klastra 2 | (wymagane) |
| `cluster2_host` | `string` | Kubernetes API endpoint | (wymagane) |
| `cluster2_token` | `string` | Token dostępowy | (wymagane, sensitive) |
| `cluster2_ca_cert` | `string` | CA certificate (base64 decoded) | (wymagane, sensitive) |
| `cluster2_id` | `number` | Cluster ID (1-255) | `2` |
| `cluster2_mesh_endpoint` | `string` | Mesh endpoint (IP:port) przez VPN | (wymagane) |

### ClusterMesh Configuration
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `clustermesh_apiserver_service_type` | `string` | Typ Service (ClusterIP, NodePort, LoadBalancer) | `"ClusterIP"` |
| `clustermesh_apiserver_replicas` | `number` | Liczba replik API Server | `1` |
| `enable_kv_store_mesh` | `bool` | Włącz KV store mesh (etcd sync) | `true` |
| `wait_for_connectivity` | `bool` | Weryfikuj connectivity po konfiguracji | `true` |
| `cilium_namespace` | `string` | Namespace Cilium | `"kube-system"` |
| `enable_external_workloads` | `bool` | Wsparcie dla external workloads | `false` |

## Zmienne wyjściowe

| Output | Opis |
|--------|------|
| `clustermesh_enabled` | Status ClusterMesh |
| `cluster1_info` | Informacje o klastrze 1 |
| `cluster2_info` | Informacje o klastrze 2 |
| `clustermesh_config` | Konfiguracja ClusterMesh |
| `cilium_namespace` | Namespace Cilium |
| `verification_commands` | Komendy do weryfikacji |
| `mesh_peering` | Status połączenia |

## Przykład użycia

### Scenariusz: Połączenie klastra vSphere + Azure

```hcl
# Utworzenie klastra vSphere
module "vsphere_cluster" {
  source = "git::https://your-repo.com/terraform-modules.git//rancher2-vsphere-cluster?ref=v1.0.0"

  cluster_name       = "k8s-vsphere-prod"
  kubernetes_version = "v1.27.6+rke2r1"

  cluster_cidr = "10.45.0.0/16"
  service_cidr = "10.46.0.0/16"

  # ... pozostała konfiguracja vSphere
}

# Utworzenie klastra Azure
module "azure_cluster" {
  source = "git::https://your-repo.com/terraform-modules.git//rancher2-azure-cluster?ref=v1.0.0"

  cluster_name       = "k8s-azure-prod"
  kubernetes_version = "v1.27.6+rke2r1"

  cluster_cidr = "10.47.0.0/16"
  service_cidr = "10.48.0.0/16"

  # WAŻNE: Non-overlapping CIDRs!
  # ... pozostała konfiguracja Azure
}

# Połączenie klastrów przez Cilium ClusterMesh
module "clustermesh" {
  source = "git::https://your-repo.com/terraform-modules.git//cilium-clustermesh?ref=v1.0.0"

  # Cluster 1 - vSphere
  cluster1_name          = "k8s-vsphere-prod"
  cluster1_host          = "https://10.10.10.100:6443"
  cluster1_token         = var.vsphere_k8s_token
  cluster1_ca_cert       = var.vsphere_k8s_ca_cert
  cluster1_id            = 1
  cluster1_mesh_endpoint = "10.10.10.101:2379"  # Prywatne IP node'a przez VPN

  # Cluster 2 - Azure
  cluster2_name          = "k8s-azure-prod"
  cluster2_host          = "https://10.20.20.100:6443"
  cluster2_token         = var.azure_k8s_token
  cluster2_ca_cert       = var.azure_k8s_ca_cert
  cluster2_id            = 2
  cluster2_mesh_endpoint = "10.20.20.101:2379"  # Prywatne IP node'a przez VPN

  # ClusterMesh config
  clustermesh_apiserver_service_type = "ClusterIP"
  clustermesh_apiserver_replicas     = 1
  enable_kv_store_mesh               = true
  wait_for_connectivity              = true

  depends_on = [
    module.vsphere_cluster,
    module.azure_cluster
  ]
}

# Outputs
output "clustermesh_status" {
  value = module.clustermesh.mesh_peering
}

output "verification_commands" {
  value = module.clustermesh.verification_commands
}
```

## Jak uzyskać credentials do klastrów?

### Z Rancher:
```bash
# Pobierz kubeconfig z Rancher
# Option 1: UI - Download kubeconfig z Rancher Dashboard

# Option 2: CLI - przez Rancher API
rancher login https://rancher.example.com --token $RANCHER_TOKEN
rancher clusters kubeconfig <cluster-id> > kubeconfig-cluster1.yaml

# Wyciągnij token i CA cert
kubectl --kubeconfig=kubeconfig-cluster1.yaml config view --raw -o jsonpath='{.users[0].user.token}'
kubectl --kubeconfig=kubeconfig-cluster1.yaml config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d
```

### Terraform variables example:
```hcl
variable "vsphere_k8s_token" {
  description = "Token dla klastra vSphere"
  type        = string
  sensitive   = true
}

variable "vsphere_k8s_ca_cert" {
  description = "CA cert dla klastra vSphere"
  type        = string
  sensitive   = true
}

variable "azure_k8s_token" {
  description = "Token dla klastra Azure"
  type        = string
  sensitive   = true
}

variable "azure_k8s_ca_cert" {
  description = "CA cert dla klastra Azure"
  type        = string
  sensitive   = true
}
```

## Mesh Endpoints - Jak je uzyskać?

Mesh endpoint to adres IP:port gdzie ClusterMesh API Server jest dostępny z drugiego klastra przez VPN.

### Opcja 1: ClusterIP (zalecane dla VPN)
```bash
# W klastrze 1
kubectl -n kube-system get svc clustermesh-apiserver
# Zapisz ClusterIP (np. 10.46.0.50) + port 2379
# Mesh endpoint: 10.46.0.50:2379

# WAŻNE: Ten ClusterIP musi być routowany przez VPN do klastra 2!
```

### Opcja 2: NodePort
```bash
# Jeśli używasz NodePort
kubectl -n kube-system get svc clustermesh-apiserver
# NodePort (np. 32379)
# Użyj IP dowolnego node'a + NodePort
# Mesh endpoint: <node-private-ip>:32379
```

### Opcja 3: LoadBalancer (jeśli masz internal LB)
```bash
# Jeśli używasz LoadBalancer (internal)
kubectl -n kube-system get svc clustermesh-apiserver
# EXTERNAL-IP (private)
# Mesh endpoint: <private-lb-ip>:2379
```

## CIDRs - Wymagania

**KRYTYCZNE:** CIDRy NIE MOGĄ się nakładać!

| Klaster | Pod CIDR | Service CIDR |
|---------|----------|--------------|
| vSphere | 10.45.0.0/16 | 10.46.0.0/16 |
| Azure | 10.47.0.0/16 | 10.48.0.0/16 |
| On-premise | 10.0.0.0/8 (np.) | - |
| VPN | - | - |

✅ Wszystkie różne = OK
❌ Nakładające się = ClusterMesh nie zadziała

## Full Mesh - Co to daje?

### 1. Pod-to-Pod Communication
```bash
# Pod w klastrze vSphere może pingować pod w Azure (i odwrotnie)
kubectl --context vsphere run -it --rm test --image=busybox -- ping <azure-pod-ip>
```

### 2. Global Service Discovery
```yaml
# Service w Azure
apiVersion: v1
kind: Service
metadata:
  name: my-api
  namespace: production
  annotations:
    io.cilium/global-service: "true"  # Udostępnij globalnie
spec:
  selector:
    app: my-api
  ports:
  - port: 80
```

```bash
# Z poda w vSphere możesz wywołać:
curl http://my-api.production.svc.clusterset.local
# Cilium zrobię load balancing również do replik w Azure!
```

### 3. Cross-Cluster Load Balancing
```yaml
# Ten sam Service w obu klastrach
# - Repliki w vSphere: 3
# - Repliki w Azure: 2
# Cilium rozłoży ruch między wszystkie 5 replik!
```

### 4. High Availability
```
Scenariusz: Klaster vSphere down
- Services automatycznie przełączają się na repliki w Azure
- Zero downtime (jeśli masz repliki w obu)
```

## Weryfikacja po deployment

### 1. Status ClusterMesh
```bash
# W klastrze 1
kubectl --context vsphere -n kube-system exec -ti ds/cilium -- cilium clustermesh status

# Output powinien pokazać:
# ✅ ClusterMesh enabled
# ✅ Remote cluster: k8s-azure-prod (ready)
```

### 2. Connectivity Test
```bash
# Uruchom test pod w klastrze 1
kubectl --context vsphere run -it --rm test-mesh \
  --image=nicolaka/netshoot \
  --restart=Never \
  -- /bin/bash

# Wewnątrz poda:
# Pinguj pod z klastra 2 (po IP)
ping <azure-pod-ip>

# Wywołaj Service z klastra 2
curl http://<service-name>.<namespace>.svc.clusterset.local
```

### 3. Sprawdź logi API Server
```bash
kubectl --context vsphere -n kube-system logs deployment/clustermesh-apiserver

# Szukaj:
# - "Connected to remote cluster"
# - Brak error'ów TLS/certificate
```

### 4. Network Policy Test
```yaml
# Utwórz test pod w vSphere i Azure
# Sprawdź czy mogą się komunikować
apiVersion: v1
kind: Pod
metadata:
  name: test-vsphere
  namespace: default
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: test-azure
  namespace: default
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
```

```bash
# Z test-vsphere pinguj test-azure
kubectl --context vsphere exec -it test-vsphere -- ping <test-azure-ip>
```

## Troubleshooting

### Problem: ClusterMesh API Server nie startuje
```bash
# Sprawdź logi
kubectl -n kube-system logs deployment/clustermesh-apiserver

# Typowe przyczyny:
# - Brak ServiceAccount
# - Błędna konfiguracja Cilium ConfigMap
# - Port 2379 zajęty
```

### Problem: Brak connectivity między klastrami
```bash
# 1. Sprawdź routing przez VPN
# Z node'a klastra 1 pinguj mesh endpoint klastra 2
ping 10.20.20.101

# 2. Sprawdź czy ClusterMesh API Server jest dostępny
telnet 10.20.20.101 2379

# 3. Sprawdź logi Cilium agent
kubectl -n kube-system logs ds/cilium | grep -i clustermesh

# 4. Sprawdź czy Secret jest utworzony
kubectl -n kube-system get secret | grep cilium-clustermesh
```

### Problem: Services nie są widoczne między klastrami
```bash
# 1. Sprawdź czy Service ma annotation
kubectl get svc <service-name> -o yaml | grep global-service

# Jeśli nie ma, dodaj:
kubectl annotate svc <service-name> io.cilium/global-service=true

# 2. Sprawdź Cilium Service cache
kubectl -n kube-system exec ds/cilium -- cilium service list | grep clusterset
```

### Problem: Nakładające się CIDRs
```bash
# Symptom: Routing loops, timeouts, duplikaty IP

# Fix: Zmień CIDRs w module klastra i re-deploy
# UWAGA: Wymaga re-creation klastra!

# W rancher2-azure-cluster lub rancher2-vsphere-cluster:
cluster_cidr = "10.XX.0.0/16"  # Zmień na unikalny
service_cidr = "10.YY.0.0/16"  # Zmień na unikalny
```

### Problem: TLS/Certificate errors
```bash
# Sprawdź czy CA cert jest poprawny
kubectl --kubeconfig=... config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d | openssl x509 -text -noout

# Sprawdź czy token jest ważny
kubectl --kubeconfig=... get nodes
```

## Network Policies (opcjonalne)

Po utworzeniu Full Mesh możesz ograniczyć komunikację używając Cilium Network Policies:

```yaml
# Przykład: Tylko namespace "production" może rozmawiać między klastrami
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: cross-cluster-production-only
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      env: production
  ingress:
  - fromEndpoints:
    - matchLabels:
        env: production
        io.cilium.k8s.policy.cluster: k8s-vsphere-prod  # Zezwalaj z vSphere
    - matchLabels:
        env: production
        io.cilium.k8s.policy.cluster: k8s-azure-prod    # Zezwalaj z Azure
  egress:
  - toEndpoints:
    - matchLabels:
        env: production
```

## Monitoring ClusterMesh

### Hubble UI
Hubble (włączony w module) pokazuje cross-cluster traffic:
```bash
# Port-forward Hubble UI
kubectl -n kube-system port-forward svc/hubble-ui 12000:80

# Otwórz http://localhost:12000
# Filtruj traffic między klastrami
```

### Metrics
```bash
# Cilium metrics
kubectl -n kube-system port-forward svc/hubble-metrics 9965:9965

# Prometheus queries:
# - cilium_clustermesh_remote_clusters (liczba remote clusters)
# - cilium_clustermesh_global_services (liczba global services)
```

## Bezpieczeństwo

1. **TLS Encryption**: Komunikacja między klastrami jest szyfrowana
2. **VPN Site-to-Site**: Dodatkowa warstwa szyfrowania
3. **Private IPs Only**: Brak publicznych IP
4. **RBAC**: ServiceAccounts z minimalnymi uprawnieniami
5. **Network Policies**: Opcjonalnie ogranicz ruch

## Uwagi

1. **Cluster IDs muszą być unikalne** (1-255) w całym mesh
2. **CIDRs nie mogą się nakładać** między klastrami
3. **VPN musi być stabilny** - mesh wymaga stałej connectivity
4. **Latency**: Komunikacja cross-cluster przez VPN może mieć większy latency
5. **Bandwidth**: Planuj bandwidth VPN dla inter-cluster traffic
6. **Monitoring**: Monitoruj health API Servers i VPN

## Upgrade

Przy upgrade Cilium w klastrach:
```bash
# 1. Upgrade Cilium w klastrze 1
helm upgrade cilium ...

# 2. Sprawdź ClusterMesh
cilium clustermesh status

# 3. Upgrade Cilium w klastrze 2
helm upgrade cilium ...

# 4. Re-apply module (jeśli potrzeba)
tofu apply
```

## Rozszerzenia

### Dodanie 3. klastra
Moduł wspiera tylko 2 klastry. Dla więcej klastrów:
- Użyj modułu wielokrotnie (cluster1+cluster2, cluster1+cluster3, cluster2+cluster3)
- Lub rozszerz moduł o dynamiczną listę klastrów

### Selective Peering
Aby przełączyć na selective:
```yaml
# Usuń annotation global-service
kubectl annotate svc <service-name> io.cilium/global-service-

# Dodaj tylko na wybrane Services
kubectl annotate svc <important-service> io.cilium/global-service=true
```

## Licencja

Ten moduł jest częścią wewnętrznej infrastruktury.

## Autor

Infrastruktura jako kod - Team DevOps
