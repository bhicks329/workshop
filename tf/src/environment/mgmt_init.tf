resource "null_resource" "init_mgmt_cluster" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
        set -e
        az aks get-credentials --resource-group ${azurerm_resource_group.env_resource_group.name} --name ${azurerm_template_deployment.aks_cluster_arm.outputs.cluster_name} --admin --overwrite-existing
        kubectl apply -f ${path.module}/k8s/helm-rbac.yaml
        kubectl apply -f ${path.module}/k8s/msi-rbac.yaml
        kubectl apply -f ${path.module}/k8s/_output/msi_identity_binding.yaml
        echo "Installing Helm into the Cluster"
        helm init --service-account tiller --wait
    EOT
  }

  depends_on = ["null_resource.msi_template", "null_resource.fix_routetable", "azurerm_template_deployment.aks_cluster_arm"]
}

resource "null_resource" "concourse_install" {
  count = "${var.is_mgmt}"
  
  provisioner "local-exec" {
    command = <<EOT
        echo "Installing Concourse"

	# concourse package install may timeout although it has been installed into the cluster. In this situation, this task should return true.
        helm install --name lbgcc --namespace lbg stable/concourse --wait --timeout 1500 --tiller-connection-timeout 1500 || true

	# if installation exists due to timeout but concourse is being installed, there are still containers being created. 
	while ( kubectl get pods -n lbg | grep -v ^NAME | grep -v Running ); do
	   echo "Concourse containers are still being created, waiting..."
	   sleep 30
	done

	# the resource should exit successfully if there is a timeout failure in order not to let it run again in the next terraform iteration
	exit 0
      EOT
  }

  depends_on = ["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "concourse_setup" {
  count = "${length(var.app_url)}"

  # it should trigger in every terraform run in order to apply the changes in pipeline.
  # later this feature is migrated to the another jenkins job
  triggers {
      version = "${timestamp()}"
  } 

  provisioner "local-exec" {
    command = <<EOT
	# port forwarding for the concourse container from local into kubernetes cluster
        export CONCOURSE_POD=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
        kubectl port-forward --namespace lbg $CONCOURSE_POD 8080 2>/dev/null &

	# looping until port forwarding is successful
	bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8080' 2>/dev/null 
        while [ "$?" -ne 0 ]; do
	  echo "Concourse port is not ready yet, trying..."
	  kill %1 2>/dev/null || true
	  sleep 3
          export CONCOURSE_POD=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
          kubectl port-forward --namespace lbg $CONCOURSE_POD 8080 2>/dev/null &
	  sleep 10
	  bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8080' 2>/dev/null
        done

	# looping until login to concourse is successful
        fly -t local login -u test -p test -c http://127.0.0.1:8080 2>/dev/null
        while [ "$?" -ne 0 ]; do
	  echo "There is a problem in login, trying..."
	  sleep 30
          fly -t local login -u test -p test -c http://127.0.0.1:8080 2>/dev/null
	done

	# concourse job creation
	sleep 10
         fly -t  local set-pipeline -p ${replace(replace(element(var.app_url, count.index), "https://", ""), "/", "_")} -c src/environment/ci/_output/pipeline-${replace(replace(element(var.app_url, count.index), "https://", ""), "/", "_")}.yaml -l src/environment/ci/_output/ci_creds.yaml -n
        sleep 2
        fly -t local unpause-pipeline -p ${replace(replace(element(var.app_url, count.index), "https://", ""), "/", "_")}
        sleep 2

	# kill the port forwarding and exiting
        kill %1 2>/dev/null|| true
	exit 0
    EOT
  }

  depends_on = ["null_resource.concourse_install", "null_resource.aquasec_setup"]
}

resource "null_resource" "rbac" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
      echo "installing rbac"
      kubectl apply -f src/environment/rbac/rbac.yaml 
    EOT
  }

  depends_on = ["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "chart_museum_setup" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
      echo "Installing Chart Museum"
      helm install --set service.type=LoadBalancer --set env.open.DISABLE_API=false stable/chartmuseum
    EOT
  }

  depends_on = ["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "istio_setup" {

  triggers {
    version = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
    az acr helm repo add --name ${var.wrregistry_helm} --subscription ${var.wrregistry_sub} -u ${var.wrregistry_username} -p ${var.wrregistry_passwd}
    helm repo update
    helm install ${var.wrregistry_helm}/istio --timeout 1200 --name istio --namespace istio-system --set servicegraph.enabled=true --set tracing.enabled=true --set grafana.enabled=true
    EOT
  }
  depends_on = ["null_resource.concourse_setup"]
}

resource "null_resource" "aquasec_setup" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
      # installing aquasec containers into the cluster. The manifest files contain the hard-coded admin user, license key and installation token
      kubectl create secret docker-registry dockerhub --docker-server="${var.wrregistry_url}" --docker-username="${var.wrregistry_username}" --docker-password="${var.wrregistry_passwd}" --docker-email=mustafa.atakan@contino.io
      kubectl create secret generic aqua-db --from-literal=password=myd8p6pdd
      kubectl apply -f src/environment/aquasec/serviceAccount.yml
      kubectl apply -f src/environment/aquasec/aqua.yml
      kubectl apply -f src/environment/aquasec/enforcer.yml

      # looping till the external IP is ready
      myurl=$(kubectl get svc  --all-namespaces | grep aqua-web | awk '{print $5}')
      while [ "$myurl" == "<pending>" ]; do
	echo "Waiting for Load Balancer IP..."
	myurl=$(kubectl get svc  --all-namespaces | grep aqua-web | awk '{print $5}')
	sleep 30
      done

      # looping until the service becomes ready
      bash -c "cat < /dev/null > /dev/tcp/$myurl/8080" 2>/dev/null
      while [ "$?" -ne 0 ]; do
      	  echo "Aquasec-web is not responding, retrying..."
	  sleep 30
	  bash -c 'cat < /dev/null > /dev/tcp/$myurl/8080' 2>/dev/null
      done

      # Adding scanner user to be used at build time
      curl --insecure -u ${var.aquasec_scan_username}:${var.aquasec_scan_password} -X POST -H "Content-Type: application/json" --data '{"id": "scanner","name": "${var.aquasec_scan_username}","password": "${var.aquasec_scan_password}","role": "scanner"}'  http://$myurl:8080/api/v1/users
      echo "scanuser IS CREATED IN AQUASEC"
    EOT
  }

  depends_on = ["null_resource.concourse_install"]
}

resource "null_resource" "msi_template" {
  triggers {
    version = "${timestamp()}"
  }

  count = "${var.is_mgmt}"

  triggers {
    time = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.msi_identity_binding_template.rendered}\" > ${path.module}/k8s/_output/msi_identity_binding.yaml"
  }

  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}

resource "null_resource" "ci_creds_template" {
  triggers {
    version = "${timestamp()}"
  }

  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.pipeline_credentials.rendered}\" > ${path.module}/ci/_output/ci_creds.yaml"
  }
}

resource "null_resource" "chartmuseum_url" {
  triggers {
    version ="${timestamp()}"
  }
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
     command = "echo \"chartmuseum-url: http://\"`kubectl get svc | grep chartmuseum | awk '{print $1}'`\".default:8080\" >> ${path.module}/ci/_output/ci_creds.yaml"
  } 
  depends_on = ["null_resource.chart_museum_setup", "null_resource.ci_creds_template"]
}

resource "null_resource" "app_setup_template" {
  triggers {
    version = "${timestamp()}"
  }

  count = "${length(var.app_url)}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.app_setup.*.rendered[count.index]}\" > ${path.module}/ci/_output/pipeline-${replace(replace(element(var.app_url, count.index), "https://", ""), "/", "_")}.yaml"
  }
}
