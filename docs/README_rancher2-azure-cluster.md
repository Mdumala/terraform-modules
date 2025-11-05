# Moduł Terraform: rancher2-azure-cluster

Moduł do automatycznego tworzenia klastrów RKE2 Kubernetes na platformie Azure zarządzanych przez Rancher Manager.

## Opis

Ten moduł Terraform umożliwia:
- Automatyczne tworzenie klastrów RKE2 na Azure za pomocą Rancher Manager
- Konfigurację Cilium CNI z zastąpieniem kube-proxy i włączonym Hubble
- Instalację Azure Cloud Provider Interface (CPI)
- Dynamiczne definiowanie grup węzłów (control plane, worker)
- **Bezpieczną konfigurację z tylko prywatnymi adresami IP** - komunikacja przez VPN site-to-site
- Zarządzanie snapshotami etcd
- Wsparcie dla CIS profiles
- Tagging zasobów Azure

## Wymagania

- OpenTofu >= v8.x
- Skonfigurowane Cloud Credentials w Rancher o nazwie "Azure"
- Istniejący Azure Resource Group
- Skonfigurowana Virtual Network (VNet) i Subnet
- **VPN Site-to-Site połączenie między Azure a środowiskiem on-premise**
- Dostęp do Azure przez VPN (maszyny nie mają publicznych IP)

## Providers

| Provider | Version | Źródło |
|----------|---------|--------|
| rancher2 | 13.0.0-rc1 | opentofu/rancher2 |
| azurerm | ~> 4.0 | opentofu/azurerm |

## Bezpieczeństwo sieci

⚠️ **WAŻNE**: Moduł domyślnie tworzy maszyny wirtualne **BEZ publicznych adresów IP** (`no_public_ip = true`).

Komunikacja odbywa się wyłącznie przez:
- Azure Private IP w ramach VNet/Subnet
- VPN Site-to-Site z siecią on-premise
- Rancher łączy się z node'ami przez prywatną sieć

Jeśli z jakiegoś powodu potrzebujesz publicznych IP (niezalecane), ustaw:
```hcl
use_private_ip = false
```

## Zmienne wejściowe

### Cluster
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `cluster_name` | `string` | Nazwa klastra w Rancher | (wymagane) |
| `kubernetes_version` | `string` | Wersja RKE2 (np. v1.27.6+rke2r1) | (wymagane) |

### Azure Connection
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `azure_environment` | `string` | Azure environment | `"AzurePublicCloud"` |
| `azure_location` | `string` | Azure region (np. westeurope) | (wymagane) |
| `azure_resource_group` | `string` | Resource Group dla VMs | (wymagane) |
| `azure_vnet` | `string` | Nazwa Virtual Network | (wymagane) |
| `azure_subnet` | `string` | Nazwa Subnet | (wymagane) |
| `azure_availability_set` | `string` | Availability Set (opcjonalnie) | `""` |
| `azure_nsg` | `string` | Network Security Group (opcjonalnie) | `""` |
| `azure_storage_account_type` | `string` | Typ dysku managed | `"StandardSSD_LRS"` |
| `azure_disk_size` | `string` | Rozmiar dysku OS w GB | `"200"` |

### VM Image
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `azure_image_publisher` | `string` | Publisher obrazu | `"Canonical"` |
| `azure_image_offer` | `string` | Offer obrazu | `"0001-com-ubuntu-server-jammy"` |
| `azure_image_sku` | `string` | SKU obrazu | `"22_04-lts-gen2"` |
| `azure_image_version` | `string` | Wersja obrazu | `"latest"` |

### Node Configuration
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `node_defs` | `map(object)` | Definicje grup node'ów | (wymagane) |
| `ssh_user` | `string` | Użytkownik SSH | `"azureuser"` |
| `ssh_public_key_path` | `string` | Ścieżka do klucza publicznego SSH | (wymagane) |
| `cloud_config_path` | `string` | Ścieżka do cloud-config template | (wymagane) |

### Network
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `cluster_cidr` | `string` | CIDR sieci pod'ów | (wymagane) |
| `service_cidr` | `string` | CIDR sieci serwisów | (wymagane) |
| `use_private_ip` | `bool` | Używaj tylko prywatnych IP | `true` |

### ETCD
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `etcd_snapshot_schedule` | `string` | Harmonogram snapshot'ów (cron) | `"0 */5 * * *"` |
| `etcd_snapshot_retention` | `number` | Liczba przechowywanych snapshot'ów | `5` |

### CSI
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `csi_cluster_id` | `string` | ID klastra dla Azure CSI | (wymagane) |

### Other
| Zmienna | Typ | Opis | Domyślna wartość |
|---------|-----|------|------------------|
| `state_confirm` | `number` | Potwierdzenia stanu klastra | `3` |
| `profile_cis` | `string` | CIS profile (pusty = wyłączone) | `""` |
| `tags` | `map(string)` | Tagi Azure | `{}` |
| `open_port` | `list(string)` | Porty do otwarcia w NSG | `[]` |

## Zmienne wyjściowe

| Output | Opis |
|--------|------|
| `cluster_id` | ID klastra Rancher (format v2) |
| `cluster_id_v1` | ID klastra Rancher (format v1) |
| `cluster_name` | Nazwa utworzonego klastra |
| `azure_location` | Region Azure |
| `azure_resource_group` | Resource Group |
| `cluster_ids_debug` | Wszystkie identyfikatory dla debugowania |

## Przykład użycia

```hcl
module "azure_cluster" {
  source = "git::https://your-repo.com/terraform-modules.git//rancher2-azure-cluster?ref=v1.0.0"

  # Cluster
  cluster_name        = "k8s-azure-prod"
  kubernetes_version  = "v1.27.6+rke2r1"

  # Azure
  azure_location       = "westeurope"
  azure_resource_group = "rg-kubernetes-prod"
  azure_vnet           = "vnet-kubernetes"
  azure_subnet         = "subnet-k8s-nodes"
  azure_nsg            = "nsg-k8s-nodes"

  # Network CIDRs (MUSZĄ być różne od vSphere!)
  cluster_cidr = "10.48.0.0/16"  # Pody
  service_cidr = "10.49.0.0/16"  # Serwisy

  # SSH
  ssh_user            = "azureuser"
  ssh_public_key_path = "${path.root}/files/id_rsa.pub"
  cloud_config_path   = "${path.root}/files/cloud_config.tftmpl"

  # CSI
  csi_cluster_id = "k8s-azure-prod"

  # Nodes - przykładowa konfiguracja HA
  node_defs = {
    control_plane = {
      name     = "azure-master"
      quantity = 3
      vm_size  = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM
      roles    = ["controlplane", "etcd"]
    }
    worker = {
      name     = "azure-worker"
      quantity = 3
      vm_size  = "Standard_D2s_v3"  # 2 vCPU, 8 GB RAM
      roles    = ["worker"]
    }
  }

  # Tags
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "kubernetes"
  }

  # Bezpieczeństwo - tylko prywatne IP (domyślne)
  use_private_ip = true
}

# Output przykładowy
output "azure_cluster_id" {
  value = module.azure_cluster.cluster_id
}
```

## Popularne rozmiary VM Azure

| Rozmiar | vCPU | RAM | Opis |
|---------|------|-----|------|
| Standard_B2s | 2 | 4 GB | Burstable, rozwój |
| Standard_D2s_v3 | 2 | 8 GB | General purpose |
| Standard_D4s_v3 | 4 | 16 GB | Control plane |
| Standard_D8s_v3 | 8 | 32 GB | Workloads |
| Standard_E4s_v3 | 4 | 32 GB | Memory-optimized |

## Struktura node_defs

```hcl
node_defs = {
  nazwa_grupy = {
    name     = "prefix-nazwy-vm"  # np. "k8s-master"
    quantity = 3                   # liczba node'ów
    vm_size  = "Standard_D4s_v3"  # rozmiar Azure VM
    roles    = ["controlplane", "etcd"]  # role w klastrze
  }
}
```

Możliwe role:
- `controlplane` - węzły control plane
- `etcd` - węzły etcd
- `worker` - węzły worker

## Sieć i bezpieczeństwo

### VPN Site-to-Site
Moduł zakłada że masz skonfigurowane:
1. **Azure VPN Gateway** w swojej VNet
2. **Local Network Gateway** wskazujący na on-premise
3. **VPN Connection** między nimi
4. **Routing** między Azure Subnet a siecią on-premise

### Network Security Group (NSG)
Jeśli określisz `azure_nsg`, zalecane reguły:

**Inbound:**
- `22` (SSH) - tylko z on-premise CIDR
- `6443` (Kubernetes API) - tylko z Rancher i on-premise
- `9345` (Rancher agent) - tylko z Rancher
- `10250` (kubelet) - wewnątrz klastra
- `2379-2380` (etcd) - tylko control plane
- `8472` (Cilium VXLAN) - wewnątrz klastra
- `4240` (Cilium health) - wewnątrz klastra

**Outbound:**
- Zezwalaj na wszystko (lub filtruj do Azure Services + on-premise)

## Cilium CNI

Moduł instaluje Cilium z:
- ✅ kube-proxy replacement (strict mode)
- ✅ Hubble UI (monitoring sieci)
- ✅ Hubble Relay
- ✅ IPAM mode: kubernetes
- ✅ Tolerations dla control plane

## Azure Cloud Provider

Moduł automatycznie konfiguruje Azure CPI, co daje:
- Integrację z Azure Load Balancer dla Services type LoadBalancer
- Zarządzanie Azure routing
- Metadata service dla node'ów

## Snapshots etcd

Domyślnie:
- Co 5 godzin (`0 */5 * * *`)
- Zachowywane 5 ostatnich snapshot'ów
- Zapisywane lokalnie na node'ach etcd

## Upgrade Strategy

- Control plane: po kolei (`concurrency: 1`)
- Workers: po kolei
- Drain przed upgrade z timeoutami
- Respektuje PodDisruptionBudgets

## CIS Hardening

Aby włączyć CIS profile:
```hcl
profile_cis = "cis-1.23"
```

## Troubleshooting

### Maszyny nie mogą połączyć się z Rancher
- Sprawdź czy VPN Site-to-Site działa
- Sprawdź routing między Azure Subnet a Rancher
- Sprawdź NSG rules (port 443 do Rancher)

### Nodes pokazują się jako "Unavailable"
- Sprawdź czy Rancher może dotrzeć do prywatnych IP
- Sprawdź port 9345 (Rancher agent)
- Sprawdź logi: `kubectl logs -n cattle-system -l app=cattle-cluster-agent`

### Cloud-init nie zadziałał
- Sprawdź `/var/log/cloud-init-output.log` na node'zie
- Sprawdź format `custom_data` (musi być base64)

### Problemy z Cilium
```bash
# Sprawdź status Cilium
cilium status

# Sprawdź connectivity
cilium connectivity test
```

## Uwagi

1. **CIDRy muszą być unikalne** - nie mogą nachodzić na:
   - Inne klastry Kubernetes
   - Azure VNet/Subnet
   - Sieć on-premise

2. **Azure Quotas** - sprawdź limity:
   - Cores per region
   - Public IPs (jeśli używasz)
   - VM families

3. **Managed Disks** - domyślnie `StandardSSD_LRS`:
   - `Standard_LRS` - HDD, tańszy
   - `StandardSSD_LRS` - SSD, balans cena/wydajność
   - `Premium_LRS` - Premium SSD, wymaga VM z obsługą Premium

4. **Cloud-init template** - musi być kompatybilny z Ubuntu 22.04 i cloud-init

## Licencja

Ten moduł jest częścią wewnętrznej infrastruktury.

## Autor

Infrastruktura jako kod - Team DevOps
