#!/bin/bash
set -eu

export baseName=${1}
export environment=${2}
export resourceGroup="mgmt-${baseName}-${environment}"
export location="uksouth"
export servicePrincipalName="sp-terraform-${baseName}-${environment}"
# export required_packages="./required_packages.cnf"

generate_manifest() {
	cat <<EOF >mgmt_manifest.json
	[
    {
      "resourceAppId": "00000002-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "1cda74f2-2616-4834-b122-5cb1b07f8a59",
          "type": "Role"
        },
        {
          "id": "311a71cc-e848-46a1-bdf8-97ff7156d8e6",
          "type": "Scope"
        }
      ]
    }
  ]
EOF
}

create_rand() {
	 md5 -q -s ${1} | cut -c1-${2}
}

create_sp() {
	echo "Looking in AD for ${servicePrincipalName}"

	# Get the app ID of the application if it exists
	appId=$(az ad app list --identifier-uri http://${servicePrincipalName} --query [].appId -o tsv)

	# Check if there is an app ID and create if not.
	if [[ -z ${appId} ]]; then
		echo "Creating application ${servicePrincipalName}"
		generate_manifest
		app=$(az ad app create --display-name ${servicePrincipalName} --required-resource-accesses @mgmt_manifest.json --identifier-uris http://${servicePrincipalName})
		appId=$(az ad app list --identifier-uri http://${servicePrincipalName} --query [].appId -o tsv)
		if [[ -z "$appId" ]]; then
			echo "Error creating principle - exiting"
			exit
		fi
	else
		echo "App already exists in AAD"

	fi

	echo
	echo "Using AppID: $appId"
	echo

	# Check and create the SP if required
	if [[ $(az ad sp list --display-name ${servicePrincipalName} --query [].appId -o tsv | wc -l) -eq 0 ]]; then
		echo "Creating Service Principle"
		spObject=$(az ad sp create --id $appId)
		if [[ -z $spObject ]]; then
			echo "Error creating Service Principle"
			exit
		fi
	else
		echo "SP already exists in AAD"
	fi

	# Check and create the SP credentials if required
	if [[ $(az ad sp credential list --id $appId -o tsv | wc -l) -eq 0 ]]; then
		echo "Creating SP Credentials"
		spCred=$(az ad sp credential reset --name http://${servicePrincipalName})
		newCreds="1"
		if [[ -z $spCred ]]; then
			echo "Error creating credentials for SP"
			exit
		fi
	else
		echo "Credentials already exist for $servicePrincipalName"
		newCreds=""
	fi

	# If credentials have changed - Update the vault
	if [[ ${newCreds} -eq 0 ]]; then
		echo "Skipping vault update ..."
	else
		echo "Setting ${servicePrincipalName}-clientId  in ${vaultName}"
		az keyvault secret set --vault-name ${vaultName} --name ${servicePrincipalName}-clientId --value ${appId}

		echo "Setting ${servicePrincipalName}-tenant in ${vaultName}"
		tenant=$(echo $spCred | jq -r .tenant)
		az keyvault secret set --vault-name ${vaultName} --name ${servicePrincipalName}-tenant --value ${tenant}

		echo "Setting ${servicePrincipalName}-password in ${vaultName}"
		password=$(echo $spCred | jq -r .password)
		az keyvault secret set --vault-name ${vaultName} --name ${servicePrincipalName}-password --value ${password}

		echo "Setting ${servicePrincipalName}-subscriptionId in ${vaultName}"
		az keyvault secret set --vault-name ${vaultName} --name ${servicePrincipalName}-subscriptionId --value ${subscriptionId}
	fi

	# Update the roles for the SP on the current subscription

	if [[ $(az role assignment list --assignee $appId -o tsv | wc -l) -eq 0 ]]; then
		echo "Assigning roles to SP"
		spId=$(az ad sp list --display-name ${servicePrincipalName} | jq -r .[].objectId)
		echo "Waiting for SP to be created"
		sleep 10
		az role assignment create --assignee-object-id ${spId} --scope /subscriptions/${subscriptionId} --role contributor
	else
		echo "Roles already assigned"
	fi

}


export random=$(create_rand ${baseName}${environment} 4)

export tfStorageAccount="${baseName}${environment}${random}"
export tfStorageContainer="${baseName}${environment}"
export vaultName="${baseName}${environment}${random}"


#  Check for required packages
while read package; do
  if ! which ${package} >/dev/null; then
	  echo "Missing ${package}, exiting..."
	  exit 1
  fi
done < ${required_packages}

# Check and display the current subscription
subscriptionId=$(az account list | jq -r ' .[] | select(.isDefault==true) | .id')
subscriptionName=$(az account list | jq -r ' .[] | select(.isDefault==true) | .name')
echo

# Check with the user we are in the right subscription
echo "Running in subscription: ${subscriptionName}"
echo "Subscription ID: ${subscriptionId}"
read -p "Are you sure? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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


# Check and create keyvault
if [[ $(az keyvault show --name ${vaultName} -o json 2>/dev/null | wc -l) -eq 0 ]]; then
	echo "Create Azure keyvault \"${vaultName}\""
	az keyvault create --resource-group ${resourceGroup} \
		--name ${vaultName} \
		--location ${location} \
		--enable-soft-delete=true \
		--enabled-for-deployment=false \
		--enabled-for-disk-encryption=false \
		--enabled-for-template-deployment=false \
		--sku=premium \
		--tags "environment=${environment}"
else
	echo "Vault \"${vaultName}\" already exists, nothing todo"
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
		--name ${tfStorageContainer} \
		--public-access blob
else
	echo "Storage Container \"${tfStorageContainer}\" already exists, nothing todo"
fi

# Create the terraform service principle
create_sp

# Grabs the objectId of the principle
spObject=$(az ad sp list --display-name ${servicePrincipalName} | jq -r .[].objectId)

# Set the keyvault policy to allow access to the SP
if [[ $(az keyvault show --name ${vaultName} --query properties.accessPolicies[].objectId -o tsv | grep -i ${spObject} | wc -l) -eq 0 ]]; then
	echo "Set the keyvault policy"
	az keyvault set-policy --name ${vaultName} --object-id ${spObject} --secret-permissions get 2>/dev/null
else
	echo "Key vault policy already set"
fi

if [ -f mgmt_manifest.json ] ; then
    rm mgmt_manifest.json
fi

echo
echo "All Done"
# Until the pull request for "az grant" is approved - a manual configuration step is required.
echo "If this is a new environment - please ensure you have clicked \"Grant Permissions\" in the portal for after running this script"
