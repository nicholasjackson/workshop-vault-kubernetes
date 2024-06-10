variable "vault_addr" {
  default = ""
}

variable "vault_namespace" {
  default = "vault"
}

resource "helm" "vault_operator" {
  cluster = variable.k8s

  repository {
    name = "hashicorp"
    url  = "https://helm.releases.hashicorp.com"
  }

  chart   = "hashicorp/vault-secrets-operator"
  version = "v0.7.1"

  namespace = variable.vault_namespace

  values_string = {
    "defaultVaultConnection.enabled" = "true"
    "defaultVaultConnection.address" = variable.vault_addr
  }
}