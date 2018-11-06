resource "null_resource" "sleep_wait" {
  provisioner "local-exec" {
    command = "sleep 15"
  }
  depends_on = ["azurerm_azuread_service_principal_password.aks_cluster"]
}


resource "azurerm_template_deployment" "aks_cluster_arm" {
  name                = "aks_arm_deployment"
  provider            = "azurerm"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"

  template_body = "${file("${path.module}/templates/aks_deploy.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    "base_name"             = "${lower(var.basename)}"
    "environment"           = "${lower(var.environment)}"
    "cluster_name"          = "aks-${lower(var.basename)}-${lower(var.environment)}"
    "os_disk_size"          = "${var.cluster_os_disk_size}"
    "agent_count"           = "${var.cluster_node_count}"
    "agent_vm_size"         = "${var.cluster_node_size}"
    "linux_admin_username"  = "azureuser"
    "ssh_RSA_public_key"    = "${tls_private_key.cluster_ssh.public_key_openssh}"
    "sp_client_id"          = "${azurerm_azuread_application.aks_cluster.application_id}"
    "sp_client_secret"      = "${random_string.aks_cluster_sp_pass.result}"
    "kubernetes_version"    = "${var.kubernetes_version}"
    "cluster_subnet_id"     = "${azurerm_subnet.cluster_subnet.id}"

  # The following value is ignored by the arm template but can be used to force a re-run.
    "force_refresh"         = "1"
  }

  deployment_mode = "Incremental"
  depends_on = ["${null_resource.sleep_wait}"]
}

resource "tls_private_key" "cluster_ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

output "cluster_name" {
  value = "${azurerm_template_deployment.aks_cluster_arm.outputs["cluster_name"]}"
}