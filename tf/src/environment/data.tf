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
    k8s-ca                = "${data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate}"
    k8s-server            = "${data.azurerm_kubernetes_cluster.cluster.kube_config.0.host}"
    k8s-token             = "${data.azurerm_kubernetes_cluster.cluster.kube_config.0.password}"
    aquasec-username      = "${var.aquasec_scan_username}"
    aquasec-passwd        = "${var.aquasec_scan_password}"
    wrregistry_username   = "${var.wrregistry_username}"
    wrregistry_passwd     = "${var.wrregistry_passwd}"
    wrregistry_url        = "${var.wrregistry_url}"
  }
}

data "template_file" "app_setup" {
  count = "${length(var.app_url)}"

  template = "${file("${path.module}/ci/templates/pipeline2.yml")}"

  vars {
    app_name    = "${replace(replace(element(var.app_url, count.index), "https://", ""), "/", "_")}"
    app_url     = "${element(var.app_url, count.index)}"
    branch_name = "${var.branch_name}"
  }
}
