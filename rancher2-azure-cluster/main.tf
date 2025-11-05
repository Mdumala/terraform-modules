# Konfiguracja maszyn dla każdej grupy node'ów
resource "rancher2_machine_config_v2" "node_config" {
  for_each = var.node_defs

  generate_name = "${var.cluster_name}-${each.value.name}"

  azure_config {
    # Azure Environment
    environment = var.azure_environment
    location    = var.azure_location

    # Resource Group i Networking
    resource_group = var.azure_resource_group
    vnet           = var.azure_vnet
    subnet         = var.azure_subnet

    # WAŻNE: Wyłączenie publicznych IP - komunikacja tylko przez prywatną sieć
    no_public_ip = var.use_private_ip

    # Network Security Group
    nsg = var.azure_nsg != "" ? var.azure_nsg : null

    # Availability Set (opcjonalnie dla HA)
    availability_set = var.azure_availability_set != "" ? var.azure_availability_set : null

    # VM Configuration
    size = each.value.vm_size

    # Storage Configuration
    storage_type = var.azure_storage_account_type
    disk_size    = var.azure_disk_size

    # Image Configuration - Ubuntu 22.04 LTS z cloud-init
    image = "${var.azure_image_publisher}:${var.azure_image_offer}:${var.azure_image_sku}:${var.azure_image_version}"

    # SSH Configuration
    ssh_user = var.ssh_user

    # Cloud-init user data
    custom_data = base64encode(templatefile(var.cloud_config_path, {
      ssh_authorized_keys = file(var.ssh_public_key_path)
    }))

    # Open Ports (jeśli NSG jest używany)
    dynamic "open_port" {
      for_each = var.open_port
      content {
        port = open_port.value
      }
    }

    # Tags
    tags = merge(
      var.tags,
      {
        "cluster"   = var.cluster_name
        "node_type" = each.value.name
      }
    )
  }
}

# Tworzenie klastra RKE2 w Rancher
resource "rancher2_cluster_v2" "cluster" {
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Timeout dla operacji na klastrze
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  # Globalna konfiguracja RKE2
  rke_config {
    machine_global_config = yamlencode({
      cni    = "cilium"
      profile = local.profile_cis != "" ? local.profile_cis : null

      # Wyłączenie kube-proxy (Cilium go zastąpi)
      disable-kube-proxy = true
      disable            = ["rke2-ingress-nginx"]

      # Konfiguracja kubelet
      kubelet-arg = [
        "max-pods=250"
      ]

      # Konfiguracja sieci
      cluster-cidr = local.cluster_cidr
      service-cidr = local.service_cidr
    })

    # Konfiguracja snapshots etcd
    etcd_snapshot_create {
      cron_expression = var.etcd_snapshot_schedule
      retention       = var.etcd_snapshot_retention
    }

    # Strategia upgrade'u
    upgrade_strategy {
      control_plane_concurrency = "1"
      worker_concurrency        = "1"

      control_plane_drain_options {
        enabled                    = true
        delete_empty_dir_data      = true
        disable_eviction           = false
        force                      = false
        grace_period               = 120
        ignore_daemon_sets         = true
        skip_wait_for_delete_timeout = 60
        timeout                    = 300
      }

      worker_drain_options {
        enabled                    = true
        delete_empty_dir_data      = true
        disable_eviction           = false
        force                      = false
        grace_period               = 120
        ignore_daemon_sets         = true
        skip_wait_for_delete_timeout = 60
        timeout                    = 300
      }
    }

    # Instalacja Azure Cloud Provider Interface (CPI)
    machine_selector_config {
      config = yamlencode({
        cloud-provider-name = "azure"
      })
    }

    # Instalacja Cilium CNI z kube-proxy replacement
    chart_values = yamlencode({
      rke2-cilium = {
        kubeProxyReplacement = "strict"
        k8sServiceHost       = "localhost"
        k8sServicePort       = "6443"

        hubble = {
          enabled = true
          relay = {
            enabled = true
          }
          ui = {
            enabled = true
          }
        }

        operator = {
          replicas = 1
        }

        ipam = {
          mode = "kubernetes"
        }

        # Tolerancje dla control plane
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          },
          {
            key      = "node-role.kubernetes.io/etcd"
            operator = "Exists"
            effect   = "NoExecute"
          }
        ]
      }
    })

    # Machine pools - dynamiczne tworzenie z definicji node'ów
    dynamic "machine_pools" {
      for_each = var.node_defs

      content {
        name                         = machine_pools.value.name
        cloud_credential_secret_name = local.cloud_credential_id
        control_plane_role           = contains(machine_pools.value.roles, "controlplane")
        etcd_role                    = contains(machine_pools.value.roles, "etcd")
        worker_role                  = contains(machine_pools.value.roles, "worker")
        quantity                     = machine_pools.value.quantity

        machine_config {
          kind = rancher2_machine_config_v2.node_config[machine_pools.key].kind
          name = rancher2_machine_config_v2.node_config[machine_pools.key].name
        }
      }
    }
  }

  # Cloud provider config dla Azure
  cloud_credential_secret_name = local.cloud_credential_id
}

# Oczekiwanie na aktywny stan klastra
resource "rancher2_cluster_sync" "cluster_wait" {
  cluster_id    = rancher2_cluster_v2.cluster.cluster_v1_id
  state_confirm = var.state_confirm

  depends_on = [
    rancher2_cluster_v2.cluster
  ]
}
