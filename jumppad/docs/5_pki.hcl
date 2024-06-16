resource "chapter" "pki" {
  title = "PKI Secrets Engine"

  tasks = {
  }

  page "introduction" {
    content = template_file("./pki/1_index.mdx", {})
  }
}