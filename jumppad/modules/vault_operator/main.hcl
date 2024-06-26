variable "vault_addr" {
  default = ""
}

variable "vault_namespace" {
  default = "vault"
}

resource "helm" "vault_operator" {
  cluster = variable.k8s

  repository {
    name = "hashicorp2"
    url  = "https://helm.releases.hashicorp.com"
  }

  chart   = "hashicorp2/vault-secrets-operator"
  version = "v0.7.1"

  retry = 2

  namespace = variable.vault_namespace

  values_string = {
    "defaultVaultConnection.enabled" = "true"
    "defaultVaultConnection.address" = variable.vault_addr
  }
}