#!/bin/bash
set -eu

create_rand() {
	if [[ $OSTYPE == 'linux-gnu' ]]; then
		md5sum <<< ${1} | cut -c1-${2}
	else
		md5 -q -s ${1} | cut -c1-${2}
	fi
}

clean() {
    echo $1 | sed 's/[^a-zA-Z0-9]//g' 
}

export baseName=${1}
export random=$(create_rand ${baseName} 4)
export resourceGroup="bootstrap-${baseName}"
export tfStorageAccount="$(clean ${baseName}${random})"
export tfStorageContainer="$(clean ${baseName})"
export location="westeurope"

# Check and display the current subscription
subscriptionId=$(az account list | jq -r ' .[] | select(.isDefault==true) | .id')
subscriptionName=$(az account list | jq -r ' .[] | select(.isDefault==true) | .name')
echo

# Check with the user we are in the right one
echo "Running in subscription: ${subscriptionName}"
echo "Subscription ID: ${subscriptionId}"
read -p "Are you sure? " 
echo # (optional) move to a new line
if [[ ! $REPLY =~ ^'yes'$ ]]; then
	[[ "$0" == "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
echo

# Check and create for resource group
if [[ $(az group show -n ${resourceGroup} -o tsv | wc -l) -eq 0 ]]; then
	echo "Creating Resource Group \"${resourceGroup}\" ..."
	az group create --name ${resourceGroup} --location ${location}
else
	echo "Resource Group \"${resourceGroup}\" already exists, nothing todo"
fi

# Check and update storage account
if [[ "$(az storage account check-name --name ${tfStorageAccount} | jq -r '.nameAvailable')" == "true" ]]; then
	echo "Storage Account \"${tfStorageAccount}\" is missing, will be created"
	az storage account create \
		--location ${location} \
		--name ${tfStorageAccount} \
		--resource-group ${resourceGroup} \
		--sku Standard_GRS \
		--encryption-services blob \
		--kind BlobStorage \
		--access-tier hot \
		--https-only
else
	echo "Storage Account \"${tfStorageAccount}\" already exists, nothing todo"
fi

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

# Use the connection string to check and create the storage account container
if [[ $(az storage container exists --name ${tfStorageContainer} | jq -r '.exists') == false ]]; then
	echo "Storage Container \"${tfStorageContainer}\" is missing, will be created"
	az storage container create \
		--name ${tfStorageContainer} 
else
	echo "Storage Container \"${tfStorageContainer}\" already exists, nothing todo"
fi

echo "Initialising TF Backend"
terraform init -reconfigure \
	-backend-config="container_name=${tfStorageContainer}" \
	-backend-config="storage_account_name=${tfStorageAccount}" \
	-backend-config="key=infra.${baseName}.tfstate" \
	-backend-config="access_key=${tfStorageKey}" \
	src/

echo "Starting TF Validate"
terraform validate -var "basename=${baseName}" src/

echo "Starting TF Apply"
terraform apply -var "basename=${baseName}" src/
