#!/bin/bash
set -eu

create_rand() {
	 md5 -q -s ${1} | cut -c1-${2}
}

load_sp() {
	echo "Checking the keyvault ${vaultName} for ${servicePrincipalName}"
	clientId=$(az keyvault secret show --name $servicePrincipalName-clientId --vault-name ${vaultName} 2>/dev/null | jq -r .value)
	if [[ -z ${clientId} ]]; then
		echo "Credentials for $servicePrincipalName not found"
	else
		echo "Getting $servicePrincipalName-clientId ..."
		clientId=$(az keyvault secret show --name $servicePrincipalName-clientId --vault-name ${vaultName} 2>/dev/null | jq -r .value)
		echo "Getting $servicePrincipalName-tenant ..."
		tenant=$(az keyvault secret show --name $servicePrincipalName-tenant --vault-name ${vaultName} 2>/dev/null | jq -r .value)
		echo "Getting $servicePrincipalName-password ..."
		password=$(az keyvault secret show --name $servicePrincipalName-password --vault-name ${vaultName} 2>/dev/null | jq -r .value)
		echo "Getting $servicePrincipalName-subscriptionId ..."
		subscription=$(az keyvault secret show --name $servicePrincipalName-subscriptionId --vault-name ${vaultName} 2>/dev/null | jq -r .value)
	fi
}

export baseName=${1}
export environment=${2}
export resourceGroup="${baseName}-${environment}"
export servicePrincipalName="sp-terraform-${baseName}-${environment}"
export random=$(create_rand ${baseName}${environment} 4)
export tfStorageAccount="${baseName}${environment}${random}"
export tfStorageContainer="${baseName}${environment}"
export vaultName="${baseName}${environment}${random}"

# Check for the AZ command line
if ! which az >/dev/null; then
	echo "Missing azure cli"
	exit 1
fi

#  Check for JQ
if ! which jq >/dev/null; then
	echo "Missing jq"
fi

# Check and display the current subscription
subscriptionId=$(az account list | jq -r ' .[] | select(.isDefault==true) | .id')
subscriptionName=$(az account list | jq -r ' .[] | select(.isDefault==true) | .name')
echo

if [ -z ${3+x} ]; then
	echo
else
	echo
	echo "Running with showCreds only."
	echo "Terraform will not be invoked"
	echo
	credsOnly="1"
fi

# Check with the user we are in the right one
echo "Running in subscription: ${subscriptionName}"
echo "Subscription ID: ${subscriptionId}"
read -p "Are you sure? " -n 1 -r
echo # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	[[ "$0" == "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
echo

#  TODO - Check for SA and bomb out if not found
# Grab the storage connection string
echo "Fetching storage connection string"
AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
	--name ${tfStorageAccount} \
	--resource-group ${resourceGroup} | jq -r '.connectionString')
export AZURE_STORAGE_CONNECTION_STRING

# Use the connection string to get the account key
echo "Fetching storage key"
tfStorageKey=$(az storage account keys list \
	--account-name ${tfStorageAccount} \
	--resource-group ${resourceGroup} 2>/dev/null | jq -r .[0].value)
export tfStorageKey

# Grab the credentials from the vault
load_sp

# # Set TF env variables
export ARM_CLIENT_ID=${clientId}
export ARM_TENANT_ID=${tenant}
export ARM_CLIENT_SECRET=${password}
export ARM_SUBSCRIPTION_ID=${subscription}

# Uncomment this line and update the lock ID if state is locked - Please be careful !!
# terraform force-unlock 212988ab-9981-fa7e-8d95-53507d5e8c1c

# Initialise Terraform
terraform init -reconfigure \
	-backend-config="container_name=${tfStorageContainer}" \
	-backend-config="storage_account_name=${tfStorageAccount}" \
	-backend-config="key=infra.${environment}.tfstate" \
	-backend-config="access_key=${tfStorageKey}" \
	src/

terraform validate -var-file vars/${baseName}-${environment}.tfvars src/
terraform apply -var-file vars/${baseName}-${environment}.tfvars src/
