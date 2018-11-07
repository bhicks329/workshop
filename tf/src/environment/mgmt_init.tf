resource "null_resource" "init_mgmt_cluster" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
        set -e
        az aks get-credentials --resource-group ${azurerm_resource_group.env_resource_group.name} --name ${azurerm_template_deployment.aks_cluster_arm.outputs.cluster_name} --admin
        kubectl apply -f ${path.module}/k8s/helm-rbac.yaml
        kubectl apply -f ${path.module}/k8s/msi-rbac.yaml
        kubectl apply -f ${path.module}/k8s/_output/msi_identity_binding.yaml
        echo "Installing Helm into the Cluster"
        helm init --service-account tiller --wait
        echo "Installing Concourse"
        helm install --name lbgcc --namespace lbg stable/concourse --wait
        export CONCOURSE_POD=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
        kubectl port-forward --namespace lbg $CONCOURSE_POD 8080 &
        sleep 5
        fly -t local login -u test -p test -c http://127.0.0.1:8080
        fly -t local sync

        fly -t  local set-pipeline -p ${var.app_name} -c src/environment/ci/_output/pipeline.yaml -l src/environment/ci/_output/ci_creds.yaml -n
        sleep 2
        fly -t local unpause-pipeline -p ${var.app_name}
        kill %1
    EOT
  } 
  
  depends_on = ["null_resource.msi_template", "null_resource.fix_routetable"]
}

resource "null_resource" "msi_template" {
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
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.pipeline_credentials.rendered}\" > ${path.module}/ci/_output/ci_creds.yaml"
  } 
}

resource "null_resource" "ci_creds_aks_config" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.azurerm_kubernetes_cluster.cluster.kube_config_raw}\" | sed 's/^/ /'  >> ${path.module}/ci/_output/ci_creds.yaml"
  }
  depends_on = ["null_resource.ci_creds_template"]
}
resource "null_resource" "app_setup_template" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.app_setup.rendered}\" > ${path.module}/ci/_output/pipeline.yaml"
  } 
}
