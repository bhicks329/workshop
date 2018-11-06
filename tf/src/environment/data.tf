data "azurerm_kubernetes_cluster" "cluster" {
  name                = "${azurerm_template_deployment.aks_cluster_arm.outputs["cluster_name"]}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
}

data "azurerm_resource_group" "cluster_node_group" {
  name = "${data.azurerm_kubernetes_cluster.cluster.node_resource_group}"
}

data "template_file" "msi_identity_binding_template" {
  template = "${file("${path.module}/k8s/templates/msi-identity.tpl")}"

  vars {
    client_id      = "${azurerm_user_assigned_identity.cluster_msi.client_id}"
    msi_id         = "${azurerm_user_assigned_identity.cluster_msi.id}"
    selector_label = "aad_auth"
    binding_name   = "msi-id"
  }

  depends_on = ["azurerm_user_assigned_identity.cluster_msi"]
}

data "template_file" "pipeline_credentials" {
  template = "${file("${path.module}/ci/templates/ci_creds.yml")}"

  vars {
    baseregistry-username = "${azurerm_container_registry.acr.admin_username}"
    baseregistry-password = "${azurerm_container_registry.acr.admin_password}"
    baseregistry-url      = "${azurerm_container_registry.acr.login_server}"
    kubeconfig            = "${data.azurerm_kubernetes_cluster.cluster.kube_config_raw}"
  }
}
