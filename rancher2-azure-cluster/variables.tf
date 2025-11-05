## Cluster ##
variable "cluster_name" {
  description = "Nazwa klastra Kubernetes w Rancher"
  type        = string
}

variable "kubernetes_version" {
  description = "Wersja Kubernetes (np. v1.27.6+rke2r1)"
  type        = string
}

## Azure Connection ##
variable "azure_environment" {
  description = "Azure environment (AzurePublicCloud, AzureUSGovernmentCloud, etc.)"
  type        = string
  default     = "AzurePublicCloud"
}

variable "azure_location" {
  description = "Azure region (np. westeurope, northeurope)"
  type        = string
}

variable "azure_resource_group" {
  description = "Nazwa Resource Group dla VMs"
  type        = string
}

variable "azure_vnet" {
  description = "Nazwa Virtual Network"
  type        = string
}

variable "azure_subnet" {
  description = "Nazwa Subnet"
  type        = string
}

variable "azure_availability_set" {
  description = "Nazwa Availability Set (opcjonalnie)"
  type        = string
  default     = ""
}

variable "azure_nsg" {
  description = "Nazwa Network Security Group (opcjonalnie)"
  type        = string
  default     = ""
}

variable "azure_storage_account_type" {
  description = "Typ dysku (Standard_LRS, Premium_LRS, StandardSSD_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "azure_disk_size" {
  description = "Rozmiar dysku OS w GB"
  type        = string
  default     = "200"
}

## VM Image ##
variable "azure_image_publisher" {
  description = "Publisher obrazu VM"
  type        = string
  default     = "Canonical"
}

variable "azure_image_offer" {
  description = "Offer obrazu VM"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "azure_image_sku" {
  description = "SKU obrazu VM"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "azure_image_version" {
  description = "Wersja obrazu VM"
  type        = string
  default     = "latest"
}

## Node Configuration ##
variable "node_defs" {
  description = "Definicje grup node'ów (nazwa, ilość, rozmiar VM, role)"
  type = map(object({
    name     = string
    quantity = number
    vm_size  = string       # np. Standard_D2s_v3
    roles    = list(string) # ["controlplane", "etcd"] lub ["worker"]
  }))
}

variable "ssh_user" {
  description = "Nazwa użytkownika SSH"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Ścieżka do pliku z kluczem publicznym SSH"
  type        = string
}

variable "cloud_config_path" {
  description = "Ścieżka do pliku z cloud-config template"
  type        = string
}

## Network ##
variable "cluster_cidr" {
  description = "CIDR sieci pod'ów (np. 10.42.0.0/16)"
  type        = string
}

variable "service_cidr" {
  description = "CIDR sieci serwisów (np. 10.43.0.0/16)"
  type        = string
}

## ETCD ##
variable "etcd_snapshot_schedule" {
  description = "Harmonogram tworzenia snapshot'ów etcd (cron format)"
  type        = string
  default     = "0 */5 * * *"
}

variable "etcd_snapshot_retention" {
  description = "Liczba zachowywanych snapshot'ów etcd"
  type        = number
  default     = 5
}

## CSI ##
variable "csi_cluster_id" {
  description = "Unikalny identyfikator klastra dla Azure CSI (np. nazwa klastra)"
  type        = string
}

## Other ##
variable "state_confirm" {
  description = "Ile razy potwierdzić stan klastra przed zakończeniem"
  type        = number
  default     = 3
}

variable "profile_cis" {
  description = "CIS profile toggle (pusty = wyłączone)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tagi Azure dla zasobów"
  type        = map(string)
  default     = {}
}

## Private Network ##
variable "open_port" {
  description = "Porty do otwarcia w NSG (jeśli używany). Domyślnie tylko komunikacja prywatna."
  type        = list(string)
  default     = []
}

variable "use_private_ip" {
  description = "Używaj tylko prywatnych IP (bez publicznych adresów)"
  type        = bool
  default     = true
}
