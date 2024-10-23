#!/bin/bash
echo login to vault

export VAULT_ADDR='http://127.0.0.1:8200'
vault login root

echo "Step 1: generate local CA"
mkdir root
openssl genrsa -out root/rootCA.key 2048
openssl req -x509 -new -nodes -key root/rootCA.key -sha256 -days 3650 -out root/rootCA.crt

echo "Step 2: generate intermediate CA"
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/internal \
     common_name="example.com Intermediate Authority" \
     issuer_name="example-dot-com-intermediate" \
     | jq -r '.data.csr' > pki_intermediate.csr

openssl x509 -req -in pki_intermediate.csr -CA root/rootCA.crt -CAkey root/rootCA.key -CAcreateserial -out intermediate-cert.pem -days 3650 -sha256 -extfile ca-ext.cnf -extensions v3_ca
cat intermediate-cert.pem root/rootCA.crt > intermediate-bundle.pem

vault write pki_int/intermediate/set-signed certificate=@intermediate-bundle.pem

echo "Step 3: create role"
vault write pki_int/roles/example-dot-com \
     issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
     allowed_domains="example.com" \
     allow_subdomains=true \
     max_ttl="720h"

vault write -format=json pki_int/issue/example-dot-com common_name="test.example.com" ttl="24h" > nginx_certs.json