resource "chapter" "vault_controller" {
  title = "Using the Vault Controller"

  tasks = {
    add_annotations_1 = resource.task.add_annotations_1
    add_annotations_2 = resource.task.add_annotations_2
    add_annotations_3 = resource.task.add_annotations_3
    add_annotations_4 = resource.task.add_annotations_4
    add_annotations_5 = resource.task.add_annotations_5
    deploy_controller = resource.task.deploy_controller
  }

  page "introduction" {
    content = file("./vault_controller/1_index.mdx")
  }

  page "static" {
    content = file("./vault_controller/2_static_secrets.mdx")
  }

  page "dynamic" {
    content = file("./vault_controller/3_database_secrets.mdx")
  }

  page "pki" {
    content = file("./vault_controller/4_pki_secrets.mdx")
  }

  page "transit" {
    content = file("./vault_controller/5_transit.mdx")
  }

  page "deploy" {
    content = file("./vault_controller/6_deploy.mdx")
  }

  page "testing" {
    content = template_file("./vault_controller/7_testing.mdx", {
      operator_url   = "https://${variable.base_url}:5001"
      controller_url = "https://${variable.base_url}:5002"
      base_url       = variable.base_url
    })
  }
}

resource "task" "add_annotations_1" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "agent_inject" {
    description = "Add the agent-inject annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-inject: "true"'
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }

  condition "role" {
    description = "Add the role annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/role: "chat"'
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }
}

resource "task" "add_annotations_2" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret" {
    description = "Add the agent-inject annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains "vault.hashicorp.com/agent-inject-secret-api: 'kv/data/chat/config'"
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }

  condition "template" {
    description = "Add the role annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-inject-template-config: |'
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }
}

resource "task" "add_annotations_3" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret" {
    description = "Add the agent-inject annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains "vault.hashicorp.com/agent-inject-secret-db: 'database/creds/writer'"
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }

  condition "template" {
    description = "Add the role annotation to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-inject-template-config: |'
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }
}

resource "task" "add_annotations_4" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret" {
    description = "Add the agent-inject-secret-pki annotation to the chat-controller.yaml file for the chat pki certificate"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains "vault.hashicorp.com/agent-inject-secret-pki: 'pki/issue/chat'"
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }

  condition "template" {
    description = "Add the template to the chat-controller.yaml file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-inject-template-pki: |'
        validate file /usr/src/chat-controller.yaml contains '{{- with pkiCert "pki/issue/chat" "common_name=chat.local.jmpd.in" "ttl=2h" -}}'
        validate file /usr/src/chat-controller.yaml contains '{{ .Cert }}{{ .CA }}{{ .Key }}'
        validate file /usr/src/chat-controller.yaml contains '{{ .Key | writeToFile "/vault/secrets/key.pem" "vault" "vault" "0644" }}'
        validate file /usr/src/chat-controller.yaml contains '{{ .CA | writeToFile "/vault/secrets/ca.pem" "vault" "vault" "0644" }}'
        validate file /usr/src/chat-controller.yaml contains '{{ .Cert | writeToFile "/vault/secrets/cert.pem" "vault" "vault" "0644" }}'
        validate file /usr/src/chat-controller.yaml contains '{{- end -}}'
      EOF

      failure_message = "Template annotation has not been correctly added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }
}

resource "task" "add_annotations_5" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "secret" {
    description = "Add the two annotations to the `chat-controller.yaml` file"

    check {
      script = <<-EOF
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-cache-enable: "true"'
        validate file /usr/src/chat-controller.yaml contains 'vault.hashicorp.com/agent-cache-use-auto-auth-token : "force"'
      EOF

      failure_message = "Annotations have not been added to the file"
    }

    solve {
      script = <<-EOF

      EOF

      timeout = 60
    }
  }
}

resource "task" "deploy_controller" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "deployment" {
    description = "Apply the `chat-controller.yaml` file"

    check {
      script = <<-EOF
        kubectl get deployments chat-controller
        if [ $? -ne 0 ]; then
          echo "Chat operator deployment not found"
          exit 1
        fi
      EOF

      failure_message = "Chat application has not been deployed"
    }

    solve {
      script = <<-EOF
        kubectl apply -f /usr/src/chat-controller.yaml
      EOF

      timeout = 60
    }
  }
}