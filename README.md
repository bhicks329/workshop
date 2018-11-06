To build the environment you need to have the following installed:

Helm
AZ Cli
JQ
Terraform

Ensure you are logged into the correct subscription  with `az login`

From the tf directory - Run `tf_apply_basic.sh ENV_NAME`

For example - tf_apply_basic.sh project-1




Once complete you need manually edit the ci_creds.yaml file as it doesn't format correct yet.


#From the shell run - 
export POD_NAME=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace lbg $POD_NAME 8080

# Then from another shell login to your concourse instance ...

fly -t local login -u test -p test -c http://127.0.0.1:8080
fly -t local sync

# Setup the piplien and unpause.
fly -t local set-pipeline -p hello_hapi -c app/ci/pipeline.yml -l tf/src/environment/ci/_output/ci_creds.yaml
sleep 2
fly -t local unpause-pipeline -p hello_hapi
sleep 2


