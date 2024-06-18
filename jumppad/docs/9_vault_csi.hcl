resource "chapter" "vault_csi" {
  title = "Using the Vault Controller"

  tasks = {
    csi_database = resource.task.csi_database
    csi_pki      = resource.task.csi_pki
    deploy_csi   = resource.task.deploy_csi
  }

  page "introduction" {
    content = file("./vault_csi/1_index.mdx")
  }

  page "database" {
    content = file("./vault_csi/2_database.mdx")
  }

  page "pki" {
    content = file("./vault_csi/3_pki.mdx")
  }

  page "deploying" {
    content = file("./vault_csi/4_deploying.mdx")
  }

  page "testing" {
    content = template_file("./vault_csi/5_testing.mdx", {
      csi_url  = "https://${variable.base_url}:5003"
      base_url = variable.base_url
    })
  }

  page "transit" {
    content = file("./vault_csi/6_transit.mdx")
  }

  page "7_summary" {
    content = file("./vault_csi/7_summary.mdx")
  }
}

resource "task" "csi_database" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "create_secret" {
    description = "Create the `SecretProviderClass` for the database secret"

    check {
      script = <<-EOF
        kubectl get secretproviderclass vault-db-creds
        if [ $? -ne 0 ]; then
          echo "SecretProviderClass does not exist"
          exit 1
        fi
      EOF

      failure_message = "Annotation has not been added to the file"
    }

    solve {
      script = <<-EOF
        kubectl apply -f - <<EOT
        apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
        kind: SecretProviderClass
        metadata:
          name: vault-db-creds
        spec:
          provider: vault
          parameters:
            roleName: 'chat'
            vaultAddress: 'http://vault.vault.svc:8200'
            objects: |
              - objectName: "dbUsername"
                secretPath: "database/creds/writer"
                secretKey: "username"
              - objectName: "dbPassword"
                secretPath: "database/creds/writer"
                secretKey: "password"
          secretObjects:
            - secretName: vault-db-creds-secret
              type: Opaque
              data:
                - objectName: dbUsername # References dbUsername below
                  key: username # Key within k8s secret for this value
                - objectName: dbPassword
                  key: password
        EOT
      EOF

      timeout = 60
    }
  }
}

resource "task" "csi_pki" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "create_secret" {
    description = "Create the `SecretProviderClass` for the PKI secret"

    check {
      script = <<-EOF
        kubectl get secretproviderclass vault-pki-creds
        if [ $? -ne 0 ]; then
          echo "SecretProviderClass does not exist"
          exit 1
        fi
      EOF

      failure_message = "SecretProviderClass vault-pki-creds  has not been created"
    }

    solve {
      script = <<-EOF
        kubectl apply -f - <<EOT
        apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
        kind: SecretProviderClass
        metadata:
          name: vault-pki-creds
        spec:
          provider: vault
          parameters:
            roleName: 'chat'
            vaultAddress: 'http://vault.vault.svc:8200'
            objects: |
              - objectName: "cert.pem"
                secretPath: "pki/issue/chat"
                method: "PUT"
                secretKey: "certificate"
                secretArgs:
                  common_name: chat.local.jmpd.in
              - objectName: "key.pem"
                secretPath: "pki/issue/chat"
                method: "PUT"
                secretKey: "private_key"
                secretArgs:
                  common_name: chat.local.jmpd.in
        EOT
      EOF

      timeout = 60
    }
  }
}

resource "task" "deploy_csi" {
  prerequisites = []

  config {
    user   = "root"
    target = variable.vscode
  }

  condition "deployment" {
    description = "Apply the `chat-csi.yaml` file"

    check {
      script = <<-EOF
        kubectl get deployments chat-csi
        if [ $? -ne 0 ]; then
          echo "Chat CSI deployment not found"
          exit 1
        fi
      EOF

      failure_message = "Chat application has not been deployed"
    }

    solve {
      script = <<-EOF
        kubectl apply -f /usr/src/chat-csi.yaml
      EOF

      timeout = 60
    }
  }
}