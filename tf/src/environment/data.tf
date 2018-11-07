data "azurerm_kubernetes_cluster" "cluster" {
  name                = "${azurerm_template_deployment.aks_cluster_arm.outputs["cluster_name"]}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
}

data "azurerm_resource_group" "cluster_node_group" {
  name = "${data.azurerm_kubernetes_cluster.cluster.node_resource_group}"
}

data "template_file" "msi_identity_binding_template" {
  template = "${file("${path.module}/k8s/templates/msi_identity_binding.tpl")}"

  vars {
    keyvault_test_cid = "${azurerm_user_assigned_identity.keyvault_test.client_id}"
    keyvault_test_rid = "${azurerm_user_assigned_identity.keyvault_test.id}"
  }

  depends_on = ["azurerm_user_assigned_identity.keyvault_test"]
}

data "template_file" "pipeline_credentials" {
  template = "${file("${path.module}/ci/templates/ci_creds.yml")}"

  vars {
    baseregistry-username = "${azurerm_container_registry.acr.admin_username}"
    baseregistry-password = "${azurerm_container_registry.acr.admin_password}"
    baseregistry-url      = "${azurerm_container_registry.acr.login_server}"
    baseregistry-name     = "${azurerm_container_registry.acr.name}"
  }
}

data "template_file" "app_setup" {
  template = "${file("${path.module}/ci/templates/pipeline.yml")}"

  vars {
    app_name    = "${var.app_name}"
    app_url     = "${var.app_url}"
    branch_name = "${var.branch_name}"
  }
}
