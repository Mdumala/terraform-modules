# Opentofu Module: Rancher vSphere Cluster

## 🧩 Opis
Ten moduł OpenTofu umożliwia utworzenie w pełni zautomatyzowanego klastra Kubernetes (RKE2) w środowisku vSphere, zarządzanego przez Rancher. Moduł:

- tworzy konfiguracje maszyn wirtualnych (master/worker) w oparciu o dane z vSphere,
- automatycznie przypisuje cloud credential na podstawie wybranego providera (np. `SDC`, `PDC`),
- instaluje kontroler sieciowy Cilium,
- wdraża integrację CPI/CSI dla vSphere,
- synchronizuje status klastra w Rancherze.

---

## 📁 Struktura repozytorium

### `data.tf`
Zawiera referencje do istniejących cloud credentiali w Rancherze:
```hcl
data "rancher2_cloud_credential" "sdc" {
  name = "SDC"
}

data "rancher2_cloud_credential" "pdc" {
  name = "PDC"
}
```

### `locals.tf`
Zawiera mapowanie providera na cloud credential oraz definicje variabli CIDR:
Cidr'y są tutaj zamiast w variablach ze wzglęu na problem z heredoc credentiale musze byc bo są brane z data
```hcl
locals {
  service_cidr = var.service_cidr
  cluster_cidr = var.cluster_cidr

  cloud_credentials_map = {
    SDC = data.rancher2_cloud_credential.sdc.id
    PDC = data.rancher2_cloud_credential.pdc.id
  }
  selected_credential_id = local.cloud_credentials_map[var.cloud_provider]
}
```

### `main.tf`
Główna logika modułu:
- Tworzenie `machine_config` dla każdej grupy node'ów (`node_defs`)
- Tworzenie zasobu `rancher2_cluster_v2` z całą konfiguracją RKE2, CPI/CSI, Cilium itd.
- Synchronizacja statusu klastra przez `rancher2_cluster_sync`

---

## 📥 Zmienne wejściowe (wymagane)

| Nazwa                    | Opis                                                                 |
|--------------------------|----------------------------------------------------------------------|
| `cluster_name`           | Nazwa klastra Rancher                                                |
| `kubernetes_version`     | Wersja Kubernetes (np. `v1.27.6+rke2r1`)                              |
| `cloud_provider`         | Alias providera, np. `SDC`, `PDC`                                     |
| `vsphere_server`         | Adres URL lub hostname vCenter                                       |
| `vsphere_user`           | Użytkownik do vSphere (np. `username@udomain`)              |
| `vsphere_password`       | Hasło użytkownika vSphere [ustawiamy w gitlab variable CI/CD]        |
| `vsphere_datacenter`     | Pełna ścieżka do datacenter, np. `/SDC`                              |
| `vsphere_datastore`      | Ścieżka do datastore                                                 |
| `vsphere_folder`         | Folder w którym tworzone są maszyny                                  |
| `vsphere_network`        | Vlan w jakim mają być maszyny                                          |
| `vsphere_resource_pool`  | Ścieżka do resource pool                                             |
| `vsphere_clone_template` | Ścieżka do template VM                                              |
| `ssh_user`               | Nazwa użytkownika dla maszyny do ssh                                 |
| `ssh_public_key_path`    | Ścieżka do pliku z kluczem publicznym                                |
| `cloud_config_path`      | Ścieżka do szablonu cloud-init (plik `.tftmpl`)                      |
| `cluster_cidr`           | CIDR dla pods w klastrze, np. `10.45.0.0/16`                         |
| `service_cidr`           | CIDR dla usług w klastrze, np. `10.46.0.0/16`                        |
| `node_defs`              | Mapa definicji pul maszyn (master/worker, z rolami i parametrami)    |

---

## 🚀 Przykład użycia
```hcl
module "rancher_vsphere_cluster" {
  source = "gitlab.com/group/rancher2-vsphere-cluster"
  version = "0.0.5"

  cluster_name        = "k8s-dev"
  kubernetes_version  = "v1.27.6+rke2r1"

  cloud_provider      = "SDC"
  vsphere_server      = "vcenter.test.net"
  vsphere_user        = "svc_rancher@vsphere.local"
  vsphere_password    = var.vsphere_password

  vsphere_datacenter     = "/SDC"
  vsphere_datastore      = "/SDC/datastore/SDC_X9100"
  vsphere_folder         = "/SDC/vm/kubernetes"
  vsphere_network        = ["/SDC/network/VLAN_xxx"]
  vsphere_resource_pool  = "/SDC/host/cluster1/Resources"
  vsphere_clone_template = "/SDC/vm/Templates/ubuntu-k8s-template"

  ssh_user            = "rancher"
  ssh_public_key_path = "${path.root}/files/id_rsa.pub"
  cloud_config_path   = "${path.root}/files/cloud_config.tftmpl"

  service_cidr        = "10.46.0.0/16"
  cluster_cidr        = "10.45.0.0/16"

  node_defs = {
    ctl_plane = {
      name     = "k8s-master"
      quantity = 1
      vcpu     = 4
      vram     = 8192
      hdd      = 200 # musi być identycznie jak dysk w template
      roles    = ["controlplane", "etcd"]
    },
    worker = {
      name     = "k8s-worker"
      quantity = 2
      vcpu     = 2
      vram     = 4096
      hdd      = 200 # musi być identycznie jak dysk w template
      roles    = ["worker"]
    }
  }
}
```

---

## 📌 Wymagania
- OpenTofu >= v8.x
- Skonfigurowane Cloud Credentials w Rancherze o nazwie `SDC`, `PDC` 
- Template VM w vSphere z obsługą cloud-init
- Dostępne zasoby na vSphere

---

## 📤 Wyjścia modułu
| Output         | Opis                                  |
|----------------|-----------------------------------------|
| `cluster_id`   | ID utworzonego klastra Rancher         |
| `cluster_name` | Nazwa utworzonego klastra              |

---

## ℹ️ Uwagi końcowe
- Mapowanie `cloud_provider => cloud credential` znajduje się wewnątrz modułu (`locals.tf`)
- Wspierane są tylko credentiale o nazwach `SDC`, `PDC` (można rozszerzyć w module)
- Parametry maszyn ustawia się przez `node_defs`
- Template cloud-init musi być dostosowany do Twojej dystrybucji systemu (np. Ubuntu/RHEL)
- Dysk na maszynie ma 200GB z czego zaalokowane jest 90GB reszta do użycia poprzez lvm

