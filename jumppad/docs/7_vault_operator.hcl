resource "chapter" "vault_operator" {
  title = "Using the Vault Operator"

  tasks = {
    configure_auth    = resource.task.configure_operator_auth
    configure_static  = resource.task.configure_operator_static
    configure_dynamic = resource.task.configure_operator_dynamic
    configure_pki     = resource.task.configure_pki
    deploy_operator   = resource.task.deploy_operator
  }

  page "introduction" {
    content = template_file("./vault_operator/1_index.mdx", {})
  }

  page "static" {
    content = template_file("./vault_operator/2_static_secret.mdx", {})
  }

  page "dynamic" {
    content = template_file("./vault_operator/3_dynamic_secret.mdx", {})
  }

  page "pki" {
    content = template_file("./vault_operator/4_pki_secret.mdx", {})
  }

  page "deploy" {
    content = template_file("./vault_operator/5_deploy.mdx", {})
  }

  page "testing" {
    content = template_file("./vault_operator/6_testing.mdx", {
      operator_url = "https://${variable.base_url}:5000"
      base_url     = variable.base_url
    })
  }
}

resource "task" "configure_operator_auth" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "auth_configured" {
    description = "Vault Auth CRD configured and deployed to the default namespace"

    check {
      script = <<-EOF
        kubeclt get vaultauth chat-auth
        if [ $? -ne 0 ]; then
          echo "VaultAuth chat-auth not found"
          exit 1
        fi
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

resource "task" "configure_operator_static" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret_configured" {
    description = "VaultStaticSecret CRD configured and deployed to the default namespace"

    check {
      script = <<-EOF
        kubeclt get vaultstaticsecret vault-static-secret
        if [ $? -ne 0 ]; then
          echo "VaultStaticSecret vault-static-secret not found"
          exit 1
        fi
      EOF

      failure_message = "Create a VaultStaticSecret CRD and deploy it to the default namespace"
    }

    solve {
      script = <<-EOF
        cat <<EOT | kubectl apply -f -
        apiVersion: secrets.hashicorp.com/v1beta1
        kind: VaultStaticSecret
        metadata:
          name: vault-static-secret
        spec:
          vaultAuthRef: chat-auth
          mount: kv
          type: kv-v2
          path: chat/config 
          refreshAfter: 60s
          destination:
            create: true
            name: chat-config
        EOT
      EOF

      timeout = 60
    }
  }
}

resource "task" "configure_operator_dynamic" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret_configured" {
    description = "VaultStaticSecret CRD configured and deployed to the default namespace"

    check {
      script = <<-EOF
        kubeclt get vaultdynamicsecret vault-database-secret
        if [ $? -ne 0 ]; then
          echo "VaultDynamicSecret vault-database-secret not found"
          exit 1
        fi
      EOF

      failure_message = "Create a VaultDynamicSecret vault-database-secret and deploy it to the default namespace"
    }

    solve {
      script = <<-EOF
        cat <<EOT | kubectl apply -f -
        ---
        apiVersion: secrets.hashicorp.com/v1beta1
        kind: VaultDynamicSecret
        metadata:
          name: vault-database-secret
        spec:
          vaultAuthRef: chat-auth
          mount: database
          path: creds/writer
          destination:
            create: true
            name: chat-database
        EOT
      EOF

      timeout = 60
    }
  }
}


resource "task" "configure_pki" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "pki_configured" {
    description = "The VaultPKISecret has been created"

    check {
      script = <<-EOF
        kubeclt get vaultpkisecret vault-pki-secret
        if [ $? -ne 0 ]; then
          echo "VaultPKISecret vault-pki-secret not found"
          exit 1
        fi
      EOF

      failure_message = "Create a VaultPKISecret CRD and deploy it to the default namespace"
    }

    solve {
      script = <<-EOF
        cat <<EOT | kubectl apply -f -
        ---
        apiVersion: secrets.hashicorp.com/v1beta1
        kind: VaultPKISecret
        metadata:
          name: vault-pki-secret
        spec:
          vaultAuthRef: chat-auth
          mount: pki
          role: chat
          commonName: chat.local.jmpd.in
          destination:
            create: true
            name: chat-pki
        EOT
      EOF

      timeout = 60
    }
  }
}

resource "task" "deploy_operator" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "deployment_created" {
    description = "Create the deployment for the chat application"

    check {
      script = <<-EOF
        kubectl get deployments chat-operator
        if [ $? -ne 0 ]; then
          echo "Chat operator deployment not found"
          exit 1
        fi
      EOF

      failure_message = "Deploy the chat operator using the command `kubectl apply -f chat-operator.yaml`"
    }

    solve {
      script = <<-EOF
        kubeclt apply -f /usr/src/chat-operator.yaml
      EOF

      timeout = 60
    }
  }
}