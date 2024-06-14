resource "chapter" "database_encryption" {
  title = "Database Encryption"

  tasks = {
    enable_transit = resource.task.enable_transit
    create_key     = resource.task.create_key
  }

  page "introduction" {
    content = template_file("./database_encryption/1_index.mdx", { db_address = variable.db_address })
  }

  page "creating_keys" {
    content = template_file("./database_encryption/2_creating_keys.mdx", { db_address = variable.db_address })
  }

  page "encrypting_data" {
    content = template_file("./database_encryption/3_encrypting_data.mdx", { db_address = variable.db_address })
  }

  page "decrypting_data" {
    content = template_file("./database_encryption/4_decrypting_data.mdx", { db_address = variable.db_address })
  }
}

resource "task" "enable_transit" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "transit_enabled" {
    description = "Transit secrets engine enabled"

    check {
      script = <<-EOF
        vault read sys/mounts | grep transit
      EOF 

      failure_message = "The transit secrets engine is not enabled"
    }

    solve {
      script = <<-EOF
        vault secrets enable transit
      EOF

      timeout = 60
    }
  }
}

resource "task" "create_key" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "key_created" {
    description = "The chat encryption key has been created"

    check {
      script = <<-EOF
        vault read transit/keys/chat
        if [ $? -ne 0 ]; then
          validate fail "Chat encryption key does not exist"
        fi
      EOF 

      failure_message = "The encryption key has not been created"
    }

    solve {
      script = <<-EOF
        vault write -f transit/keys/chat type=rsa-4096 || true
      EOF

      timeout = 60
    }
  }
}