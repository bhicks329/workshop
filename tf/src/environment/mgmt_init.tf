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

resource "null_resource" "ci_creds_template" {
  count = "${var.is_mgmt}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.pipeline_credentials.rendered}\" > ${path.module}/ci/_output/ci_creds.yaml"
  } 
}
