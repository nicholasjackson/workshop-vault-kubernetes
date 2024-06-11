#!/bin/bash

# Configure database secrets
vault secrets enable database

vault write database/config/chat \
    plugin_name=mongodb-database-plugin \
    allowed_roles=writer,reader \
    connection_url="mongodb://{{username}}:{{password}}@10.100.0.180:27017/admin?tls=false" \
    username="chat" \
    password="password"

# Rotate root password
vault write -force database/rotate-root/chat

# Create the roles
vault write database/roles/writer \
    db_name=chat \
    creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' \
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/reader \
    db_name=chat \
    creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' \
    default_ttl="1h" \
    max_ttl="24h"

# Configure Database Encryption
vault secrets enable transit

# Create the key
vault write -f transit/keys/hcat type=rsa-4096

# Configure Kubernetes Auth
vault write auth/kubernetes/role/chat \
  bound_service_account_names=chat \
  bound_service_account_namespaces=default \
  token_policies=chat
  ttl=24h

# Create the policy
vault policy write chat - <<EOF
path "database/creds/writer" {
  capabilities = ["read", "create"]
}

path "transit/encrypt/chat" {
  capabilities = ["create","update"]
}
EOF