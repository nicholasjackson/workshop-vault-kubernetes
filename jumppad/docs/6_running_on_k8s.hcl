resource "chapter" "running_on_k8s" {
  title = "Running on Kubernetes"

  tasks = {
    fetch_secrets  = resource.task.fetch_secrets
    enable_auth    = resource.task.enable_auth
    configure_auth = resource.task.configure_auth
    create_policy  = resource.task.create_policy
    create_role    = resource.task.create_role
    create_sa      = resource.task.create_sa
  }

  page "introduction" {
    content = template_file("./running_on_k8s/1_index.mdx", { db_address = variable.db_address })
  }

  page "configuration" {
    content = template_file("./running_on_k8s/2_configure_auth.mdx", {})
  }

  page "policy" {
    content = template_file("./running_on_k8s/2_defining_policy.mdx", { db_address = variable.db_address })
  }

  page "roles" {
    content = template_file("./running_on_k8s/3_creating_roles.mdx", { db_address = variable.db_address })
  }

  page "service_account" {
    content = template_file("./running_on_k8s/4_creating_sa.mdx", { db_address = variable.db_address })
  }
}

resource "task" "fetch_secrets" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "transit_enabled" {
    description = "Token and CA certificate files created"

    check {
      script = <<-EOF
        validate file exists "/usr/src/k8s.crt"
        validate file exists "/usr/src/k8s.token"
      EOF

      failure_message = "The transit sec"
    }

    solve {
      script = <<-EOF
        kubectl get secret vault-k8s-auth-secret -n vault -o json | jq -r '.data."ca.crt"' | base64 -d > /usr/src/k8s.crt
        kubectl get secret vault-k8s-auth-secret -n vault -o json | jq -r '.data.token' | base64 -d > /usr/src/k8s.token
      EOF

      timeout = 60
    }
  }
}

resource "task" "enable_auth" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "auth_enabled" {
    description = "The Kubernetes authentication method has been enabled"

    check {
      script = <<-EOF
        vault auth list | grep kubernetes
      EOF

      failure_message = "The transit sec"
    }

    solve {
      script = <<-EOF
        vault auth enable kubernetes
      EOF

      timeout = 60
    }
  }
}

resource "task" "configure_auth" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "auth_enabled" {
    description = "The Kubernetes authentication method has been configured"

    check {
      script = <<-EOF
        vault read auth/kubernetes/config
      EOF

      failure_message = "The Kubernetes authentication method has not been configured"
    }

    solve {
      script = <<-EOF
        vault write auth/kubernetes/config \
          token_reviewer_jwt=@/usr/src/k8s.token \
          kubernetes_host="https://kubernetes.default.svc:443" \
          kubernetes_ca_cert=@/usr/src/k8s.crt
      EOF

      timeout = 60
    }
  }
}

resource "task" "create_policy" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "policy_created" {
    description = "The policy has been created"

    check {
      script = <<-EOF
        vault policy read chat
        if [ $? -ne 0 ]; then
          validate fail "Policy does not exist"
        fi
      EOF

      failure_message = "The policy has not been created"
    }

    solve {
      script = <<-EOF
        vault policy write chat - <<EOT
        path "database/creds/writer" {
          capabilities = ["read", "create"]
        }

        path "transit/encrypt/chat" {
          capabilities = ["create","update"]
        }

        path "transit/decrypt/chat" {
          capabilities = ["create","update"]
        }

        path "kv/data/chat/config" {
          capabilities = ["read"]
        }

        path "pki/issue/chat" {
          capabilities = ["create", "update"]
        }
        EOT
      EOF

      timeout = 60
    }
  }

  condition "policy_correct" {
    description = "The policy contains the correct permissions"

    check {
      script = <<-EOF
        set -e
        vault policy read chat | grep 'path "database/creds/writer" {'
        vault policy read chat | grep 'path "transit/encrypt/chat" {'
        vault policy read chat | grep 'path "transit/decrypt/chat" {'
        vault policy read chat | grep 'path "kv/data/chat/config" {'
        vault policy read chat | grep 'path "pki/issue/chat" {'
      EOF

      failure_message = "The policy does not contain the correct permissions"
    }
  }
}

resource "task" "create_role" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "role_created" {
    description = "The role has been created"

    check {
      script = <<-EOF
        vault read auth/kubernetes/role/chat
        if [ $? -ne 0 ]; then
          validate fail "Role does not exist"
        fi
      EOF

      failure_message = "Please create the role"
    }

    solve {
      script = <<-EOF
        vault write auth/kubernetes/role/chat \
          bound_service_account_names=chat \
          bound_service_account_namespaces=default \
          token_policies=chat
          ttl=24h
      EOF

      timeout = 60
    }
  }
}

resource "task" "create_sa" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "service_account_created" {
    description = "The service account has been created"

    check {
      script = <<-EOF
        kubectl get serviceaccount chat
      EOF

      failure_message = ""
    }

    solve {
      script = <<-EOF
        cat <<EOT | kubectl apply -f -
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: chat
        automountServiceAccountToken: false
        EOT
      EOF

      timeout = 60
    }
  }
}