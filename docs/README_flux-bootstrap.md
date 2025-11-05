# Module flux-bootstrap

🚀 Bootstrapuje FluxCD v2 na Kubernetes poprzez git-ops.

## Zmienne

- `gitlab_project_id` – ID GitLab projektu
- `git_repo_url` – URL repozytorium Git, zawierającego katalog klastrów
- `git_branch` – branch (domyślnie `main`)
- `gotk_pvc_path` – lokalizacja manifestu PVC (np. `files/flux/gotk-pvc.yaml`)
- `kubernetes_host`, `kubernetes_token`, `kubernetes_ca_cert` – dane do K8s API
- `git_username`, `git_password`, `git_ca_cert` – dane do logowania do Git
- `path` – folder w repo, gdzie Flux deployuje manifesty (`clusters/<nazwa>`)
- `components_extra` – dodatkowe komponenty Flux
- `flux_version` – wersja FluxCD

## Przykład użycia

```hcl
module "flux" {
  source = "../modules/flux-bootstrap"

  gitlab_project_id     = data.gitlab_project.id
  git_repo_url          = var.git_repo_url
  git_branch            = "main"
  gotk_pvc_path         = "${path.module}/files/flux/gotk-pvc.yaml"

  kubernetes_host       = module.cluster.kubernetes_host
  kubernetes_token      = var.flux_kubernetes_token
  kubernetes_ca_cert    = var.flux_kubernetes_ca

  git_username          = var.flux_git_username
  git_password          = var.flux_git_password
  git_ca_cert           = var.git_ca_cert

  path                  = "clusters/${var.cluster_name}"
  components_extra      = ["image-reflector-controller","image-automation-controller"]
  flux_version          = "v2.6.4"
}
