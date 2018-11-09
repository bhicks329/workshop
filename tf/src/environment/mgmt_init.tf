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
  
  depends_on = ["null_resource.msi_template"]
}

resource "null_resource" "concourse_install" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
        echo "Installing Concourse"
        helm install --name lbgcc --namespace lbg stable/concourse --wait
      EOT
  }
  depends_on = ["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "concourse_setup" {
  count = "${var.is_mgmt}"

  triggers {
      version = "${timestamp()}"
  } 
  provisioner "local-exec" {
    command = <<EOT
        export CONCOURSE_POD=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
        echo "checking whether port forward is running"
        ps -ef | grep kubectl
        kubectl port-forward --namespace lbg $CONCOURSE_POD 8080 &
        sleep 5
        fly -t local login -u test -p test -c http://127.0.0.1:8080
        fly -t local sync
        fly -t  local set-pipeline -p ${var.app_name} -c src/environment/ci/_output/pipeline2.yaml -l src/environment/ci/_output/ci_creds.yaml -n
        sleep 2
        fly -t local unpause-pipeline -p ${var.app_name}
        sleep 10
        kill %1
    EOT
  }

  depends_on = ["null_resource.concourse_install"]
}

resource "null_resource" "rbac" {
  count = "${var.is_mgmt}"
 
  provisioner "local-exec" {
    command = <<EOT
      echo "installing rbac"
      kubectl apply -f src/environment/rbac/rbac.yaml 
    EOT
  }

  depends_on=["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "chart_museum_setup" {
  count = "${var.is_mgmt}"
  provisioner "local-exec" {
    command = <<EOT
      echo "Installing Chart Museum"
      helm install --set service.type=LoadBalancer --set env.open.DISABLE_API=false stable/chartmuseum
      echo "chartmuseum-url: http://"`kubectl get svc | grep chartmuseum | awk '{print $1}'`".default:8080" >> ${path.module}/ci/_output/ci_creds.yaml
    EOT
  }
  depends_on=["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "istio_chart_setup" {
  count = "${var.is_mgmt}"
  triggers {
      version = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      OS="$(uname)"
      if [ "x$${OS}" = "xDarwin" ] ; then
        OSEXT="osx"
      else
        OSEXT="linux"
      fi
      
      curl -L https://git.io/getLatestIstio --output getIstio.sh
      ISTIO_VERSION="${var.istio-version}"
      curl -L https://github.com/istio/istio/releases/download/$${ISTIO_VERSION}/istio-$${ISTIO_VERSION}-$${OSEXT}.tar.gz | tar xz
      cd istio-"${var.istio-version}"/install/kubernetes/helm/
      helm package istio
      az acr helm repo add --name "${azurerm_container_registry.acr.name}"
      az acr helm push --force istio-"${var.istio-version}".tgz --name "${azurerm_container_registry.acr.name}"
      EOT
  }
  depends_on=["null_resource.chart_museum_setup"]
}

resource "null_resource" "istio_setup" {
  count = "${var.is_mgmt}"
  triggers {
      version = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
    helm repo update
    helm install ${azurerm_container_registry.acr.name}/istio --name istio --namespace istio-system --set servicegraph.enabled=true --set tracing.enabled=true --set grafana.enabled=true
    EOT
  }
  depends_on=["null_resource.istio_chart_setup"]
}

resource "null_resource" "aquasec_setup" {
  count = "${var.is_mgmt}"
  
  provisioner "local-exec" {
    command = <<EOT
      kubectl create secret docker-registry dockerhub --docker-server="${var.wrregistry-url}" --docker-username="${var.wrregistry-username}" --docker-password="${var.wrregistry-passwd}" --docker-email=mustafa.atakan@contino.io
      kubectl create secret generic aqua-db --from-literal=password=myd8p6pdd
      kubectl apply -f src/environment/aquasec/serviceAccount.yml
      kubectl apply -f src/environment/aquasec/aqua.yml
      kubectl apply -f src/environment/aquasec/enforcer.yml
      sleep 60
      myurl=$(kubectl get svc  --all-namespaces | grep aqua-web | awk '{print $5}')
      curl --insecure -u administrator:myadmin77 -X POST -H "Content-Type: application/json" --data '{"id": "scanner","name": "scanner","password": "myscan77","role": "scanner"}'  http://$myurl:8080/api/v1/users
      echo "scan user created"
    EOT
  }
  depends_on=["null_resource.init_mgmt_cluster"]
}

resource "null_resource" "msi_template" {
  triggers {
    version = "${timestamp()}"
  } 
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.msi_identity_binding_template.rendered}\" > ${path.module}/k8s/_output/msi_identity_binding.yaml"
  } 

  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}

resource "null_resource" "ci_creds_template" {
  triggers {
    version ="${timestamp()}"
  }
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.pipeline_credentials.rendered}\" > ${path.module}/ci/_output/ci_creds.yaml"
  } 
}

resource "null_resource" "app_setup_template" {
  triggers {
    version ="${timestamp()}"
  }
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.app_setup.rendered}\" > ${path.module}/ci/_output/pipeline2.yaml"
  } 
}
