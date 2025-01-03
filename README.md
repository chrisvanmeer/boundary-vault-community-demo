# HashiCorp Boundary and Vault CE Demonstration

This demo will create the following resources on Azure:

- 1 server VM which has `docker`, `boundary-enterprise` and `vault` installed.
- 1 client VM with just a vanilla install

## Pre-requisites

1. Valid credentials for Azure where you must be allowed to create resource groups.
2. Access to a valid Boundary Enterprise license

## Usage

### Create

```shell
git clone https://github.com:chrisvanmeer/boundary-vault-community-demo
cd boundary-vault-community-demo
vim boundary.hclic  ## Put your license key in here
terraform init
terraform apply -target module.deploy
terraform apply -target module.configure_vault -target module.configure_client -target module.configure_boundary
terraform apply  ## to add the final outputs
terraform apply -target module.deploy -var="restricted_nsg=true"  ## restrict public incoming traffic on client
export BOUNDARY_ADDR="http://$(terraform output -json boundary_ip_address | jq -r .):9200"
export BOUNDARY_SCOPE_ID="$(terraform output -json boundary_scope_id | jq -r .)"
export BOUNDARY_AUTH_METHOD_ID="$(terraform output -json boundary_auth_method_id | jq -r .)"
export BOUNDARY_AUTHENTICATE_PASSWORD_LOGIN_NAME="$(terraform output boundary_user_login | jq -r .)"
export BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD="$(terraform output boundary_user_password | jq -r .)"
boundary authenticate password -password=env://BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD
boundary connect ssh -target-name client
```

### Remove

```shell
cd boundary-vault-community-demo
terraform destroy -target module.configure_vault -target module.configure_client -target module.configure_boundary
terraform destroy  ## destroy remaining infrastructure
```

## Author

- Chris van Meer <chris@atcomputing.nl>
