resource "container_registry" "k8s" {
  hostname = "registry.k8s.io"
}

resource "k8s_cluster" "k3s" {

  network {
    id = resource.network.local.meta.id
  }

  image {
    name = "shipyardrun/k3s:v1.27.5"
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
  depends_on = [module.vault_controller]

  source = "./modules/vault_operator"

  variables = {
    k8s        = resource.k8s_cluster.k3s
    vault_addr = "http://vault.vault.svc.cluster.local:8200"
  }
}