module "docs" {
  source = "./docs"

  variables = {
    vscode      = resource.container.vscode.meta.id
    network     = resource.network.local.meta.id
    db_address  = resource.container.mongo.network.0.ip_address
    docs_url    = variable.docs_url
    base_url    = variable.base_url
    vault_token = module.vault_controller.output.vault_outputs.vault_token
    vault_addr  = docker_ip()
  }
}