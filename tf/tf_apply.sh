#!/bin/bash
set -eu

export required_packages="./required_packages.cnf"

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
		echo "Skipping vault update and loading loading existing SP credentials ..."
		echo "Getting $servicePrincipalName-clientId ..."
		appId=$(az keyvault secret show --name $servicePrincipalName-clientId --vault-name ${vaultName} 2>/dev/null | jq -r .value)

		echo "Getting $servicePrincipalName-tenant ..."
		tenant=$(az keyvault secret show --name $servicePrincipalName-tenant --vault-name ${vaultName} 2>/dev/null | jq -r .value)

		echo "Getting $servicePrincipalName-password ..."
		password=$(az keyvault secret show --name $servicePrincipalName-password --vault-name ${vaultName} 2>/dev/null | jq -r .value)

		echo "Getting $servicePrincipalName-subscriptionId ..."
		subscriptionId=$(az keyvault secret show --name $servicePrincipalName-subscriptionId --vault-name ${vaultName} 2>/dev/null | jq -r .value)
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

export baseName=${1}
export environment=${2}
export resourceGroup="mgmt-${baseName}-${environment}"
export servicePrincipalName="sp-aks-terraform-${baseName}-${environment}"
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

# Adding home directory value to the configuration file
if [[ ! $(grep home_dir ./vars/${baseName}-${environment}.tfvars) ]]; then
   echo "home_dir value does not exist in the variable file, adding..."
   printf "\nhome_dir = \"$(echo $HOME)\"\n" >> ./vars/${baseName}-${environment}.tfvars
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

# # Set TF env variables
export ARM_CLIENT_ID=${appId}
export ARM_TENANT_ID=${tenant}
export ARM_CLIENT_SECRET=${password}
export ARM_SUBSCRIPTION_ID=${subscriptionId}

# Uncomment this line and update the lock ID if state is locked - Please be careful !!
# terraform force-unlock 212988ab-9981-fa7e-8d95-53507d5e8c1c

# Initialise Terraform
terraform init -reconfigure \
	-backend-config="container_name=${tfStorageContainer}" \
	-backend-config="storage_account_name=${tfStorageAccount}" \
	-backend-config="key=infra.${environment}.tfstate" \
	-backend-config="access_key=${tfStorageKey}" \
	src/

# The block below for debugging purposes, delete it before delivering to customer
mkdir -p $HOME/terraconfig
echo "export ARM_CLIENT_ID=${appId}" > $HOME/terraconfig/.terraconfig
echo "export ARM_TENANT_ID=${tenant}" >> $HOME/terraconfig/.terraconfig
echo "export ARM_CLIENT_SECRET=${password}" >> $HOME/terraconfig/.terraconfig
echo "export ARM_SUBSCRIPTION_ID=${subscriptionId}" >> $HOME/terraconfig/.terraconfig
printf "terraform init -reconfigure \
	-backend-config=\"container_name=${tfStorageContainer}\" \
	-backend-config=\"storage_account_name=${tfStorageAccount}\" \
	-backend-config=\"key=infra.${environment}.tfstate\" \
	-backend-config=\"access_key=${tfStorageKey}\" \
	${PWD}/src/\n" >> $HOME/terraconfig/.terraconfig

terraform validate -var-file vars/${baseName}-${environment}.tfvars src/
terraform apply -var-file vars/${baseName}-${environment}.tfvars src/