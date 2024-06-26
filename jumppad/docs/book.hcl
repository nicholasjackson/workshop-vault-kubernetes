variable "network" {
  default = ""
}

variable "vscode" {
  default = ""
}

variable "base_url" {
  default = ""
}

variable "docs_url" {
  default = ""
}

variable "db_address" {
  default = ""
}

variable "vault_token" {
  default = ""
}

variable "vault_addr" {
  default = ""
}

resource "book" "spring_vault" {
  title = "Integrating Vault and Kubernetes"

  chapters = [
    resource.chapter.vault_k8s_overview,
    resource.chapter.static_secrets,
    resource.chapter.database_secrets,
    resource.chapter.database_encryption,
    resource.chapter.pki,
    resource.chapter.running_on_k8s,
    resource.chapter.vault_operator,
    resource.chapter.vault_controller,
    resource.chapter.vault_csi,
  ]
}

resource "docs" "docs" {
  network {
    id = variable.network
  }

  content = [
    resource.book.spring_vault
  ]

  assets = "${dir()}/assets"
}