resource "azurerm_template_deployment" "aks_cluster" {
  name                = "aks_arm_deployment"
  provider            = "azurerm.sp"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"

  template_body = "${file("${path.module}/templates/aks_deploy.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "baseName"                     = "${var.basename}"
    "environment"                  = "${var.environment}"
    "osDiskSizeGB"                 = "${var.cluster_os_disk_size}"
    "agentCount"                   = "${var.cluster_node_count}"
    "agentVMSize"                  = "${var.cluster_node_size}"
    "linuxAdminUsername"           = "azureuser"
    "sshRSAPublicKey"              = "${tls_private_key.cluster_ssh.public_key_openssh}"
    "servicePrincipalClientId"     = "${azurerm_azuread_service_principal.aks_cluster.id}"
    "servicePrincipalClientSecret" = "${random_string.aks_cluster_sp_pass.result}"
    "kubernetesVersion"            = "${var.kubernetes_version}"
  }

  deployment_mode = "Incremental"
}

resource "tls_private_key" "cluster_ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}
