resource "null_resource" "init_mgmt_cluster" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = <<EOT
        az aks get-credentials --resource-group ${azurerm_resource_group.aks_resource_group.name} --name ${azurerm_template_deployment.aks_cluster_arm.outputs.cluster_name} --admin
        kubectl apply -f ${path.module}/k8s/helm-rbac.yaml
        helm init --service-account tiller
        helm install stable/concourse
    EOT
  }

  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}
