# vault-pki-demo-setup-script
Script to setup a PKI demo using the steps found in this [guide](https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine)

## Run Vault
```bash
vault server -dev -dev-root-token-id root
```

## Run the script
```bash
./setup.sh
```