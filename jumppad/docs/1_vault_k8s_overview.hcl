resource "chapter" "vault_k8s_overview" {
  title = "K8s Overview"


  page "introduction" {
    content = template_file("./vault_k8s_overview/1_introduction.mdx", { db_address = variable.db_address })
  }

page "chatapp" {
    content = template_file("./vault_k8s_overview/2_chatapp_introduction.mdx", { db_address = variable.db_address })
  }

page "vault_overview" {
    content = template_file("./vault_k8s_overview/3_vault_overview.mdx", { db_address = variable.db_address })
  }

}