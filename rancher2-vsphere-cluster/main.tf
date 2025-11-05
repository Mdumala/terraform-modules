
#######################
# Resource: Machine Config (node template) for each group of nodes
#######################
resource "rancher2_machine_config_v2" "node_config" {
  # Tworzymy konfigurację maszyny dla każdej grupy węzłów zdefiniowanej w node_defs
  for_each      = var.node_defs
  generate_name = replace(each.value.name, "_", "-") # generuje unikalną nazwę (Rancher doda losowy sufiks)

  vsphere_config {
    # Ustawienia specyficzne dla vSphere:
    creation_type = var.config_creation_type
    clone_from    = var.vsphere_clone_template
    datacenter    = var.vsphere_datacenter
    datastore     = var.vsphere_datastore
    folder        = var.vsphere_folder
    network       = var.vsphere_network
    pool          = var.vsphere_resource_pool

    # Opcjonalne parametry vApp i inne
    vapp_ip_allocation_policy = "dhcp" # zgodnie z oryginałem lub innymi wymaganiami
    vapp_ip_protocol          = "IPv4"
    graceful_shutdown_timeout = 5

    # Włączamy unikalny UUID dysku (wymagane np. przez Kubernetes)
    cfgparam = ["disk.enableUUID=TRUE"]

    # Specyfikacja hardware VM:
    cpu_count   = each.value.vcpu
    memory_size = each.value.vram
    disk_size   = each.value.hdd

    # Cloud-init / user-data dla instancji: wczytujemy treść z pliku szablonu i podstawiamy wartości.
    cloud_config = templatefile(var.cloud_config_path, {
      ssh_user             = var.ssh_user,
      ssh_public_key       = file(var.ssh_public_key_path),
    })
  }
}

#######################
# Resource: Rancher Cluster (RKE2) definition
#######################
resource "rancher2_cluster_v2" "cluster" {
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  default_pod_security_admission_configuration_template_name = "rancher-restricted"

  # Timeouty (opcjonalnie można zmienić lub przekazać jako zmienne jeśli potrzebne)
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  rke_config {
    # Globalne ustawienia RKE2 (CNI, inne flagi)
    machine_global_config = <<-EOF
      cloud-provider-name: rancher-vsphere
      cni: cilium
      cluster-cidr: "${local.cluster_cidr}"
      service-cidr: "${local.service_cidr}"
      disable-kube-proxy: true
      etcd-expose-metrics: false
      disable: rke2-ingress-nginx
      kubelet-arg:
        - max-pods=250
      profile: "${local.profile_cis}"
      
    EOF

    registries {
      configs {
        hostname                = "hostname:port"
        auth_config_secret_name = "secretname"
        insecure                = false
        ca_bundle               = file(var.gitlab_ca_pem)
      }
    }

    # Ustawienia specyficzne dla Cilium (chart_values)
    chart_values = <<-EOF
      rke2-cilium:
        kubeProxyReplacement: true
        kubeProxyReplacementHealthzBindAddr: "0.0.0.0:10256"
        k8sServiceHost: "localhost"
        k8sServicePort: 6443
        chainingMode: "none"
        hubble:
          enabled: true
          relay:
            enabled: true
          ui:
            enabled: true
      rancher-vsphere-cpi:
        vCenter:
          host: "${var.vsphere_server}"
          port: 443
          username: "${var.vsphere_user}"
          password: "${var.vsphere_password}"
          datacenters: "${var.vsphere_datacenter}"
          insecureFlag: true
        credentialsSecret:
          name: "vsphere-cpi-credentials"
          generate: true
        cloudControllerManager:
          tolerations:
            - key: "node-role.kubernetes.io/etcd"
              operator: "Exists"
              effect: "NoExecute"
            - key: "node.cloudprovider.kubernetes.io/uninitialized"
              operator: "Exists"
              effect: "NoSchedule"
            - key: "node-role.kubernetes.io/control-plane"
              operator: "Exists"
              effect: "NoSchedule"
      rancher-vsphere-csi:
        vCenter:
          host: "${var.vsphere_server}"
          port: 443
          clusterId: "${var.csi_cluster_id}"
          username: "${var.vsphere_user}"
          password: "${var.vsphere_password}"
          datacenters: "${var.vsphere_datacenter}"
          datastore: "${var.vsphere_datastore}"
          insecureFlag: true
        blockVolumeSnapshot:
          enabled: true  
        csiController:
          csiResizer:
            enabled: true
          nodeSelector:
            node-role.kubernetes.io/control-plane: "true"
          tolerations:
            - key: "node-role.kubernetes.io/etcd"
              operator: "Exists"
              effect: "NoExecute"
            - key: "node.cloudprovider.kubernetes.io/uninitialized"
              operator: "Exists"
              effect: "NoSchedule"
            - key: "node-role.kubernetes.io/control-plane"
              operator: "Exists"
              effect: "NoSchedule"
        storageClass:
          enabled: true
          isDefault: false
          name: "flux"
          storagePolicyName: "${var.vsphere_storagePolicyName}"
          datastoreURL: "${var.vsphere_datastoreURL}"
          reclaimPolicy: Delete
    EOF

    # Strategia aktualizacji (upgrade_strategy)
    upgrade_strategy {
      control_plane_concurrency = "1"
      worker_concurrency        = "1"
      control_plane_drain_options {
        enabled               = true
        delete_empty_dir_data = true
      }
      worker_drain_options {
        enabled               = true
        delete_empty_dir_data = true
      }
    }

    # Konfiguracja etcd (snapshoty co 5 godzin, retencja 5 snapshotów)
    etcd {
      snapshot_schedule_cron = var.etcd_snapshot_schedule
      snapshot_retention     = var.etcd_snapshot_retention
    }

    # Dynamiczne definiowanie pul maszyn (machine_pools) na podstawie mapy var.node_defs
    dynamic "machine_pools" {
      for_each = var.node_defs
      content {
        # Używamy klucza mapy, aby określić role:
        cloud_credential_secret_name = local.selected_credential_id
        control_plane_role           = contains(machine_pools.value.roles, "controlplane")
        etcd_role                    = contains(machine_pools.value.roles, "etcd")
        worker_role                  = contains(machine_pools.value.roles, "worker")
        name                         = machine_pools.value.name
        quantity                     = machine_pools.value.quantity

        # Powiązanie z utworzoną wyżej konfiguracją maszyny
        machine_config {
          kind = rancher2_machine_config_v2.node_config[machine_pools.key].kind
          name = replace(rancher2_machine_config_v2.node_config[machine_pools.key].name, "_", "-")

        }
      }
    }
  }
}

#######################
# Resource: Cluster Sync – czekaj, aż klaster będzie aktywny
#######################
resource "rancher2_cluster_sync" "cluster_wait" {
  cluster_id    = rancher2_cluster_v2.cluster.cluster_v1_id
  state_confirm = var.state_confirm
}