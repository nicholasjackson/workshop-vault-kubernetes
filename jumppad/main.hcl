variable "docs_url" {
  default = "http://localhost"
}

variable "install_vault" {
  default = true
}

variable "disable_registry" {
  default = true
}

variable "db_address" {
  default = "10.100.0.180"
}

variable "registry_ip_address" {
  default = "10.100.0.183"
}

resource "network" "local" {
  subnet = "10.100.0.0/16"
}

output "VAULT_ADDR" {
  value = module.vault_controller.output.vault_addr
}

output "VAULT_TOKEN" {
  value = module.vault_controller.output.vault_outputs.vault_token
}

output "KUBECONFIG" {
  value = resource.k8s_cluster.k3s.kube_config.path
}