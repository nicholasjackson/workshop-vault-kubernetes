resource "chapter" "vault_operator" {
  title = "Using the Vault Operator"

  tasks = {
    configure_auth = resource.task.configure_operator_auth
  }

  page "introduction" {
    content = template_file("./vault_operator/1_index.mdx", {})
  }
}

resource "task" "configure_operator_auth" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "auth_configured" {
    description = ""

    check {
      script = <<-EOF
        kubeclt get vaultauth chat-auth
      EOF

      failure_message = "Create a VaultAuth CRD and deploy it to the default namespace"
    }

    solve {
      script = <<-EOF
        cat <<EOT | kubectl apply -f -
        apiVersion: secrets.hashicorp.com/v1beta1
        kind: VaultAuth
        metadata:
          name: chat-auth
        spec:
          method: kubernetes
          mount: kubernetes 
          kubernetes:
            role: chat
            serviceAccount: chat
        EOT
      EOF

      timeout = 60
    }
  }
}