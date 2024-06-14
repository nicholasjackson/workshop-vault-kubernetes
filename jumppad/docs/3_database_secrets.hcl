resource "chapter" "database_secrets" {
  title = "Database Secrets"

  tasks = {
    enable_database    = resource.task.enable_database
    configure_database = resource.task.configure_database
    configure_roles    = resource.task.configure_roles
  }

  page "introduction" {
    content = template_file("./database_secrets/1_index.mdx", { db_address = variable.db_address })
  }

  page "configuring_database" {
    content = template_file("./database_secrets/2_configuring_database.mdx", { db_address = variable.db_address })
  }

  page "creating_roles" {
    content = template_file("./database_secrets/3_creating_roles.mdx", { db_address = variable.db_address })
  }

  page "generating_credentials" {
    content = template_file("./database_secrets/4_generating_credentials.mdx", { db_address = variable.db_address })
  }
}

resource "task" "enable_database" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "database_enabled" {
    description = "Vault database engine is enabled"

    check {
      script = <<-EOF
      vault read sys/mounts | grep database
      EOF 

      failure_message = "Run the previous command to enable the database engine"
    }

    solve {
      script = <<-EOF
      # Adding || true means that should the command fail, the skip script will still pass
      # Vault will return an error if the database secrets engine is already enabled
      vault secrets enable database || true
      EOF

      timeout = 60
    }
  }
}

resource "task" "configure_database" {
  prerequisites = [resource.task.enable_database.meta.id]

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "database_configured" {
    description = "Vault database engine has been configured"

    check {
      script = <<-EOF
      vault read database/config/chat
      EOF

      failure_message = "Run the previous command to enable the database engine"
    }

    solve {
      script = <<-EOF
        vault write database/config/chat \
          plugin_name=mongodb-database-plugin \
          allowed_roles=writer,reader \
          connection_url="mongodb://{{username}}:{{password}}@${variable.db_address}:27017/admin?tls=false" \
          username="root" \
          password="password"
      EOF

      timeout = 60
    }
  }

  condition "root_rotated" {
    description = "The root credentials have been rotated"

    check {
      script = <<-EOF
        validate history contains "vault write -force database/rotate-root/chat"
      EOF

      failure_message = "Run the previous command to enable the database engine"
    }

    solve {
      script = <<-EOF
        vault write -force database/rotate-root/chat
      EOF

      timeout = 60
    }
  }
}

resource "task" "configure_roles" {
  prerequisites = [resource.task.configure_database.meta.id]

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "writer_created" {
    description = "The writer role has been created"

    check {
      script = <<-EOF
        vault read database/roles/writer
      EOF

      failure_message = "Run the command to create the writer role"
    }

    solve {
      script = <<-EOF
        vault write database/roles/writer \
          db_name=chat \
          creation_statements='{ "db": "admin", "roles": [ {"role": "readWrite", "db": "chat"}] }' \
          default_ttl="1h" \
          max_ttl="24h"
      EOF

      timeout = 60
    }
  }

  condition "reader_created" {
    description = "The reader role has been created"

    check {
      script = <<-EOF
        vault read database/roles/reader
      EOF

      failure_message = "Run the command to create the reader role"
    }

    solve {
      script = <<-EOF
        vault write database/roles/reader \
          db_name=chat \
          creation_statements='{ "db": "admin", "roles": [ {"role": "read", "db": "chat"}] }' \
          default_ttl="1h" \
          max_ttl="24h"
      EOF

      timeout = 60
    }
  }
}