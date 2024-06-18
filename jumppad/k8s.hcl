resource "k8s_cluster" "k3s" {

  network {
    id = resource.network.local.meta.id
  }

  image {
    name = "shipyardrun/k3s:v1.27.5"
  }

  config {
    docker {
      no_proxy = ["registry.k8s.io", "pkg.dev", "amazonaws.com"]
    }
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
  depends_on = ["module.vault_controller"]

  source = "./modules/vault_operator"

  variables = {
    k8s        = resource.k8s_cluster.k3s
    vault_addr = "http://vault.vault.svc.cluster.local:8200"
  }
}

resource "ingress" "chat_operator" {
  port = 5001

  target {
    resource = resource.k8s_cluster.k3s
    port     = 5001

    config = {
      service   = "chat-operator"
      namespace = "default"
    }
  }
}

resource "ingress" "chat_controller" {
  port = 5002

  target {
    resource = resource.k8s_cluster.k3s
    port     = 5002

    config = {
      service   = "chat-controller"
      namespace = "default"
    }
  }
}

resource "ingress" "chat_csi" {
  port = 5003

  target {
    resource = resource.k8s_cluster.k3s
    port     = 5003

    config = {
      service   = "chat-csi"
      namespace = "default"
    }
  }
}