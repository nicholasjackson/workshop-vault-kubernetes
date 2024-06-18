resource "chapter" "static_secrets" {
  title = "Static Secrets"

  tasks = {
    enable_secrets = resource.task.enable_secrets
    adding_secrets = resource.task.adding_secrets
  }

  page "introduction" {
    content = template_file("./static_secrets/1_index.mdx", { db_address = variable.db_address })
  }

  page "adding" {
    content = template_file("./static_secrets/2_adding_secrets.mdx", { db_address = variable.db_address })
  }
}

resource "task" "enable_secrets" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "kv_enabled" {
    description = "Vault kv engine is enabled"

    check {
      script = <<-EOF
        vault read sys/mounts | grep kv | grep version:2
      EOF 

      failure_message = "Run the previous command to enable the database engine"
    }

    solve {
      script = <<-EOF
        vault secrets enable -version=2 kv --path=kv
      EOF

      timeout = 60
    }
  }
}

resource "task" "adding_secrets" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "kv_enabled" {
    description = "Secret created"

    check {
      script = <<-EOF
        vault kv get kv/chat/config | grep api_key
      EOF 

      failure_message = "Create a secret at kv/chat/config"
    }

    solve {
      script = <<-EOF
        vault kv put kv/chat/config api_key=abc1234567
      EOF

      timeout = 60
    }
  }
}