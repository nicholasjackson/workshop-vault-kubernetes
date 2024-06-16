resource "chapter" "vault_controller" {
  title = "Using the Vault Controller"

  tasks = {
    add_annotations_1 = resource.task.add_annotations_1
  }

  page "introduction" {
    content = template_file("./vault_controller/1_index.mdx", {})
  }

  page "static" {
    content = template_file("./vault_controller/2_static_secrets.mdx", {})
  }

  page "dynamic" {
    content = template_file("./vault_controller/3_database_secrets.mdx", {})
  }

  page "pki" {
    content = template_file("./vault_controller/4_pki_secrets.mdx", {})
  }

  page "transit" {
    content = template_file("./vault_controller/5_transit.mdx", {})
  }

  page "deploy" {
    content = template_file("./vault_controller/6_deploy.mdx", {})
  }

  page "testing" {
    content = template_file("./vault_controller/7_testing.mdx", {})
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