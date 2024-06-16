resource "chapter" "pki" {
  title = "PKI Secrets Engine"

  tasks = {
    enable_pki       = resource.task.enable_pki
    generate_root    = resource.task.generate_root
    create_cert_role = resource.task.create_cert_role
  }

  page "introduction" {
    content = template_file("./pki/1_index.mdx", {})
  }

  page "ca" {
    content = template_file("./pki/2_ca.mdx", {})
  }

  page "certs" {
    content = template_file("./pki/3_certs.mdx", {})
  }
}

resource "task" "enable_pki" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "condition_name" {
    description = "Enable the PKI secrets engine"

    check {
      script = <<-EOF
        vault read sys/mounts | grep pki
      EOF

      failure_message = "The PKI secrets engine is not enabled. Enable it with the command `vault secrets enable pki`."
    }

    solve {
      script = <<-EOF
        vault secrets enable pki || true
      EOF

      timeout = 60
    }
  }
}

resource "task" "generate_root" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "root_created" {
    description = "Create the root certificate for the PKI secrets engine"

    check {
      script = <<-EOF
        vault list pki/issuers
        if [ $? -ne 0 ]; then
          exit 1
        fi
      EOF

      failure_message = "Run the command to generate the root certificate"
    }

    solve {
      script = <<-EOF
        vault write pki/root/generate/internal \
          common_name=local.jmpd.in \
          ttl=8760h
      EOF

      timeout = 60
    }
  }
}

resource "task" "create_cert_role" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "role_created" {
    description = "Create the role to issue certificates"

    check {
      script = <<-EOF
        vault read pki/roles/chat
        if [ $? -ne 0 ]; then
          exit 1
        fi
      EOF

      failure_message = "Run the command to generate the chat role"
    }

    solve {
      script = <<-EOF
        vault write pki/roles/chat \
          allowed_domains=chat.local.jmpd.in \
          allow_bare_domains=true \
          max_ttl=72h
      EOF

      timeout = 60
    }
  }
}