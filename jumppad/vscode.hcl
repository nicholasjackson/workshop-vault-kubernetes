resource "template" "bashrc" {

  source = <<-EOF
  export PATH="$${PATH}:/opt/java/bin:/usr/local/bin/gradle/gradle-8.7/bin"
  export JAVA_HOME="/opt/java"
  EOF

  destination = "${data("vscode")}/.bashrc"
}

resource "template" "vscode_settings" {

  source = <<-EOF
  {
      "workbench.colorTheme": "GitHub Dark",
      "editor.fontSize": 16,
      "workbench.iconTheme": "material-icon-theme",
      "terminal.integrated.fontSize": 16
  }
  EOF

  destination = "${data("vscode")}/settings.json"
}

resource "template" "vscode_jumppad" {

  source = <<-EOF
  {
  "tabs": [
    {
      "name": "Docs",
      "uri": "${variable.docs_url}",
      "type": "browser",
      "active": true
    },
    {
      "name": "Terminal",
      "location": "editor",
      "type": "terminal"
    }
  ]
  }
  EOF

  destination = "${data("vscode")}/workspace.json"
}

resource "container" "vscode" {

  network {
    id = resource.network.local.meta.id
  }

  image {
    name = "nicholasjackson/kubernetes-vault-vscode:v0.0.3"
  }

  volume {
    source      = "./working"
    destination = "/usr/src"
  }

  volume {
    source      = resource.template.vscode_jumppad.destination
    destination = "/usr/src/.vscode/workspace.json"
  }

  volume {
    source      = resource.template.vscode_settings.destination
    destination = "/usr/src/.vscode/settings.json"
  }

  volume {
    source      = "/var/run/docker.sock"
    destination = "/var/run/docker.sock"
  }

  volume {
    source      = resource.k8s_cluster.k3s.kube_config.path
    destination = "/root/.kube/config"
  }

  volume {
    source      = resource.template.bashrc.destination
    destination = "/root/.bashrc"
  }

  environment = {
    KUBE_CONFIG_PATH = "/root/.kube/config"
    KUBECONFIG       = "/root/.kube/config"
    DEFAULT_FOLDER   = "/usr/src"
    LC_ALL           = "C"
    VAULT_ADDR       = module.vault_controller.output.vault_addr
    VAULT_TOKEN      = module.vault_controller.output.vault_outputs.vault_token
  }

  // vscode
  port {
    local = 8000
    host  = 8000
  }

  health_check {
    timeout = "100s"

    http {
      address       = "http://localhost:8000/"
      success_codes = [200, 302, 403]
    }
  }

  //resources {
  //  gpu {
  //    driver     = "nvidia"
  //    device_ids = ["0"]
  //  }
  //}
}