resource "null_resource" "init_mgmt_cluster" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
        set -e
        az aks get-credentials --resource-group ${azurerm_resource_group.env_resource_group.name} --name ${azurerm_template_deployment.aks_cluster_arm.outputs.cluster_name} --admin
        kubectl apply -f ${path.module}/k8s/helm-rbac.yaml
        kubectl apply -f ${path.module}/k8s/msi-rbac.yaml
        kubectl apply -f ${path.module}/k8s/_output/msi_identity_binding.yaml
        helm init --service-account tiller --wait
        helm install stable/concourse
    EOT
  } 

  depends_on = ["null_resource.msi_template"]
}

resource "null_resource" "msi_template" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.msi_identity_binding_template.rendered}\" > ${path.module}/k8s/_output/msi_identity_binding.yaml"
  } 

  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}


esource "null_resource" "init_concourse" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
      set -e
      helm install --name lbgcc --namespace lbg stable/concourse
      kubectl get pods --all-namespaces
      echo "Sleeping 150 seconds..."
      sleep 150
      kubectl get pods --all-namespaces
      export POD_NAME=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
      echo "Visit http://127.0.0.1:8080 to use Concourse"
      kubectl port-forward --namespace lbg $POD_NAME 8080
    EOT
  } 

  depends_on = ["null_resource.msi_template"]
}


helm install --name lbgcc --namespace lbg stable/concourse
kubectl get pods --all-namespaces
echo "Sleeping 150 seconds..."
sleep 150
kubectl get pods --all-namespaces
export POD_NAME=$(kubectl get pods --namespace lbg -l "app=lbgcc-web" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use Concourse"
kubectl port-forward --namespace lbg $POD_NAME 8080