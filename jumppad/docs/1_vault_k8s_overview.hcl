resource "chapter" "vault_k8s_overview" {
  title = "K8s Overview"


  page "introduction" {
    content = template_file("./vault_k8s_overview/1_introduction.mdx", { db_address = variable.db_address })
  }

}