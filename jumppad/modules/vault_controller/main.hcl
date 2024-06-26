variable "install_vault" {
  default = true
}

variable "k8s" {
  default = ""
}

variable "k8s_config" {
  default = ""
}

variable "vault_namespace" {
  default = "vault"
}

resource "helm" "csi_driver" {
  cluster = variable.k8s

  repository {
    name = "secrets-store-csi-driver"
    url  = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  }

  chart   = "secrets-store-csi-driver/secrets-store-csi-driver"
  retry   = 2
  timeout = "200s"

  namespace = "kube-system"

  values = "./config/csi-values.yaml"
}

# Configure the Vault Kubernetes service account
resource "k8s_config" "vault_auth" {
  depends_on = ["resource.helm.csi_driver"]
  cluster    = variable.k8s

  paths = [
    "./config/vault_k8s_service_account.yaml",
  ]

  wait_until_ready = true
}

resource "helm" "vault" {
  depends_on = ["resource.k8s_config.vault_auth"]
  cluster    = variable.k8s

  repository {
    name = "hashicorp"
    url  = "https://helm.releases.hashicorp.com"
  }

  retry = 2

  chart   = "hashicorp/vault" # When repository specified this is the name of the chart
  version = "v0.27.0"         # Version of the chart when repository specified

  namespace = variable.vault_namespace

  values = "./config/vault-values.yaml"
}

# Initialize the Vault server and configure
resource "exec" "vault_init" {
  depends_on = ["resource.helm.vault"]

  image {
    name = "shipyardrun/hashicorp-tools:v0.11.0"
  }

  script = file("./config/init_vault.sh")

  volume {
    source      = variable.k8s_config
    destination = "/root/.kube/config"
  }

  environment = {
    VAULT_ADDR = "http://${resource.ingress.vault_http.local_address}"
    KUBECONFIG = "/root/.kube/config"
  }
}

resource "ingress" "vault_http" {
  port = 8200

  target {
    resource = variable.k8s
    port     = 8200

    config = {
      service   = "vault"
      namespace = variable.vault_namespace
    }
  }
}

output "vault_addr" {
  value = "http://${resource.ingress.vault_http.local_address}"
}
output "vault_outputs" {
  value = resource.exec.vault_init.output
}