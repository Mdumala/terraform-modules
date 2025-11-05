# Dodaj PVC i inne pliki do repozytorium GitLab
resource "gitlab_repository_file" "flux_gotk_pvc" {
  project               = var.gitlab_project_id
  file_path             = "${var.path}/gotk-pvc.yaml"
  branch                = var.git_branch
  content               = file(var.gotk_pvc_content)
  author_email          = var.author_email
  author_name           = var.author_name
  commit_message        = var.commit_message
  overwrite_on_create   = true
  encoding              = "text"
}

resource "flux_bootstrap_git" "flux_gitlab" {

  components_extra = var.components_extra
  cluster_domain = var.cluster_domain
  path           = var.bootstrap_path
  kustomization_override = file(var.kustomization_override_path)
  version = var.flux_version

  depends_on = [gitlab_repository_file.flux_gotk_pvc]
}
