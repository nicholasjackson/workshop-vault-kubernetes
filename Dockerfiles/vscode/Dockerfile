FROM ghcr.io/jumppad-labs/vscode:vscode-v0.5.2

ARG TARGETARCH
ARG VAULT_VERSION=1.15.6

# Install default packages
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    curl \
    wget \
    zip \
    git \
    jq \
    build-essential \
    postgresql-client \
    gnupg

# Install Mongo client
RUN wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
  echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
  apt-get update && \
  apt-get install -y mongodb-mongosh


# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
  apt-get update && \
  apt-get install -y helm 

# Install Vault
RUN wget -O vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip && \
  unzip vault.zip && \
  mv vault /usr/local/bin

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" && \
  mv ./kubectl /usr/local/bin/kubectl && \
  chmod +x /usr/local/bin/kubectl

# Install VSCode extensions
RUN code-server --install-extension hashicorp.terraform && \
    code-server --install-extension hashicorp.hcl && \
    code-server --install-extension github.github-vscode-theme && \
    code-server --install-extension pkief.material-icon-theme

# Clean packages
RUN rm -rf /var/lib/apt/lists/*