#!/bin/bash

# Configure database secrets
vault secrets enable database

vault write database/config/chat \
  plugin_name=mongodb-database-plugin \
  allowed_roles=writer,reader \
  connection_url="mongodb://{{username}}:{{password}}@10.100.0.180:27017/admin?tls=false" \
  username="root" \
  password="password"

# Rotate root password
vault write -force database/rotate-root/chat

# Create the roles
vault write database/roles/writer \
  db_name=chat \
  creation_statements='{ "db": "admin", "roles": [{"role": "readWrite", "db": "chat"}] }' \
  default_ttl="1h" \
  max_ttl="24h"

vault write database/roles/reader \
  db_name=chat \
  creation_statements='{ "db": "admin", "roles": [{"role": "read", "db": "chat"}] }' \
  default_ttl="1h" \
  max_ttl="24h"

# Configure Database Encryption
vault secrets enable transit

# Create the key
vault write -f transit/keys/chat type=rsa-4096

# Enable PKI
vault secrets enable pki

vault write pki/root/generate/internal \
  common_name=local.jmpd.in \
  ttl=8760h

vault write pki/roles/chat \
  allowed_domains=chat.local.jmpd.in \
  allow_bare_domains=true \
  max_ttl=72h

# Enable kubernetes auth
vault auth enable kubernetes

# Configure kubernetes auth
kubectl get secret vault-k8s-auth-secret -n vault -o json | jq -r '.data."ca.crt"' | base64 -d > ./k8s.crt
kubectl get secret vault-k8s-auth-secret -n vault -o json | jq -r '.data.token' | base64 -d > ./k8s.token

vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat ./k8s.token)" \
  kubernetes_host="https://kubernetes.default.svc:443" \
  kubernetes_ca_cert=@./k8s.crt

# Configure Kubernetes Auth
vault write auth/kubernetes/role/chat \
  bound_service_account_names=chat \
  bound_service_account_namespaces=default \
  token_policies=chat
  ttl=24h

# Enable the kv engine
vault secrets enable -version=2 kv

# Write some secrets
vault kv put kv/chat/config api_key=abc1234567

# Create the policy
vault policy write chat - <<EOF
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
EOF