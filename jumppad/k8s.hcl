resource "k8s_cluster" "k3s" {

  network {
    id = resource.network.local.meta.id
  }
}

module "vault_controller" {
  source = "./modules/vault_controller"

  variables = {
    k8s        = resource.k8s_cluster.k3s
    k8s_config = resource.k8s_cluster.k3s.kube_config.path
  }
}

module "vault_operator" {
  source = "./modules/vault_operator"

  variables = {
    k8s        = resource.k8s_cluster.k3s
    vault_addr = "http://vault.vault.svc.cluster.local:8200"
  }
}