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
    baseregistry-username = "${azurerm_container_registry.acr.username}"
    baseregistry-password = "${azurerm_container_registry.acr.password}"
    baseregistry-url      = "${azurerm_container_registry.acr.username.url}"
    kubeconfig            = "${data.azurerm_kubernetes_cluster.cluster.kubeconfig}"
  }

  depends_on = ["azurerm_user_assigned_identity.cluster_msi"]
}
