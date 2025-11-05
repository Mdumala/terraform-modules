###############
# Variables - input parameters for the module
###############
variable "cluster_name" {
  description = "Nazwa tworzonego klastra Kubernetes w Rancher"
  type        = string
}
variable "kubernetes_version" {
  description = "Wersja Kubernetes (RKE2) dla klastra"
  type        = string
}
variable "cloud_provider" {
  description = "Short name of cloud provider, used to select credential (e.g. SDC, PDC)"
  type        = string
}
variable "vsphere_server" {
  description = "Adres serwera vSphere"
  type        = string
}
variable "vsphere_user" {
  description = "Użytkownik do autoryzacji w vSphere"
  type        = string
}
variable "vsphere_password" {
  description = "Hasło do autoryzacji w vSphere"
  type        = string
}

variable "vsphere_datacenter" {
  description = "Domyślne vSphere Datacenter, gdzie tworzyć VM"
  type        = string
}

variable "vsphere_datastore" {
  description = "Datastore dla maszyn wirtualnych"
  type        = string
}
variable "vsphere_storagePolicyName" {
  description = "Nazwa storagePolicyName"
  type        = string
  default     = ""
}
variable "vsphere_datastoreURL" {
  description = "Adres datastoreURL"
  type        = string
  default     = ""
}

variable "vsphere_folder" {
  description = "Folder w vSphere na VM"
  type        = string
}
variable "vsphere_network" {
  description = "Nazwa sieci vSphere dla VM"
  type        = list(string)
}
variable "vsphere_resource_pool" {
  description = "Ścieżka do zasobu / resource pool w vSphere, gdzie stawiane są VM"
  type        = string
}
variable "vsphere_clone_template" {
  description = "Ścieżka/nazwa VM lub template, z którego klonujemy nowe maszyny"
  type        = string
}
variable "node_defs" {
  description = "Mapa definicji grup węzłów (np. master/worker) wraz z parametrami"
  type = map(object({
    name     = string # prefiks nazwy węzła
    quantity = number # liczba instancji w grupie
    vcpu     = number # CPU count
    vram     = number # Memory (MB)
    hdd      = number # Disk size (GB)
    roles    = list(string)
  }))
}
variable "ssh_user" {
  description = "Nazwa użytkownika do ustawienia w cloud-init (domyślnie 'rancher')"
  type        = string
  default     = "rancher"
}

variable "cloud_config_path" {
  description = "Ścieżka do pliku cloud-config (szablonu cloud-init dla maszyn w klastrze)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Ścieżka do klucz publicznego"
  type        = string
}

variable "state_confirm" {
  description = "(Optional) Wait until active status is confirmed a number of times (wait interval of 5s). Default: 1 means no confirmation (int)"
  type        = number
  default     = 3
}

variable "config_creation_type" {
  description = "(Optional) Creation type when creating a new virtual machine. Supported values: vm, template, library, legacy. Default legacy (string)"
  type        = string
  default     = "template"
}
variable "csi_cluster_id" {
  description = "ŚNazwa klastra na potrzeby vsphere-csi"
  type        = string
}

## Network ##

variable "cluster_cidr" {
  description = "Cluster CIDR subnet"
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR subnet"
  type        = string
}

## ETCD ##

variable "etcd_snapshot_schedule" {
  description = "Cron schedule do snapshotów etcd"
  type        = string
  default     = "0 */5 * * *"
}

variable "etcd_snapshot_retention" {
  description = "Ile snapshotów etcd ma być przechowywanych"
  type        = number
  default     = 5
}


### PRIVATE REGISTRY ###

variable "gitlab_ca_pem" {
  description = "Ścieżka caBundle dla gita"
  type        = string
}


### CIS PROFILE ###

variable "profile_cis" {
  description = "Wajcha do uruchamiania profilu CIS, pusta zmienna nie uruchamia CIS"
  type        = string
  default     = ""
}
