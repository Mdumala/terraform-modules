variable "gitlab_project_id" {
  description = "ID projektu GitLab, w którym będą dodawane pliki Flux (np. storage PVC)"
  type        = string
}
variable "path" {
  description = "Ścieżka w repo, w której Flux utworzy katalog z manifestami (np. clusters/my-cluster)"
  type        = string
}
variable "git_branch" {
  description = "Branch w repozytorium, na którym Flux będzie pracował (domyślnie 'main')"
  type        = string
  default     = "main"
}
variable "gotk_pvc_content" {
  description = "Ścieżka lokalna do manifestu PVC wykorzystanego przez Flux (np. files/flux/gotk-pvc.yaml)"
  type        = string
}
variable "author_email" {
  description = "Email osoby commitującej"
  type        = string
}
variable "author_name" {
  description = "Nazwa autora commitu"
  type        = string
}
variable "commit_message" {
  description = "Wiadomość commitu"
  type        = string
}
variable "cluster_domain" {
  description = "Nazwa domenowa klastra"
  type        = string
}
variable "bootstrap_path" {
  description = "Ścieżka względna do katalogu głównego repozytorium. Po określeniu synchronizacja klastra będzie ograniczona do tej ścieżki (niezmienna)."
  type        = string
}
variable "kustomization_override_path" {
  description = "Plik kustomizacji do nadpisana "
  type        = string
}
variable "flux_version" {
  description = "Wersja fluxa"
  type        = string
}
variable "components_extra" {
  description = "Dodatkowe komponenty Flux do zainstalowania"
  type        = list(string)
}
