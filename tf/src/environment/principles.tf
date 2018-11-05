# Create the Service principle for the AKS Cluster
resource "azurerm_azuread_application" "aks_cluster" {
  name                       = "aks-${lower(var.basename)}-${lower(var.environment)}-${lower(random_string.aks_cluster_sp_suffix.result)}"
  homepage                   = "https://aks-${var.basename}-${var.environment}-${lower(random_string.aks_cluster_sp_suffix.result)}"
  identifier_uris            = ["https://aks-${var.basename}-${var.environment}-${lower(random_string.aks_cluster_sp_suffix.result)}"]
  reply_urls                 = ["https://aks-${var.basename}-${var.environment}-${lower(random_string.aks_cluster_sp_suffix.result)}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

resource "azurerm_azuread_service_principal" "aks_cluster" {
  application_id = "${azurerm_azuread_application.aks_cluster.application_id}"
}

resource "azurerm_azuread_service_principal_password" "aks_cluster" {
  service_principal_id = "${azurerm_azuread_service_principal.aks_cluster.id}"
  value                = "${random_string.aks_cluster_sp_pass.result}"
  end_date             = "2020-01-01T01:02:03Z"
}

resource "random_string" "aks_cluster_sp_suffix" {
  length  = 4
  special = false
}

resource "random_string" "aks_cluster_sp_pass" {
  length  = 24
  special = true
}

resource "azurerm_user_assigned_identity" "cluster_msi" {
  resource_group_name = "${data.azurerm_kubernetes_cluster.cluster.node_resource_group}"
  location            = "${azurerm_resource_group.env_resource_group.location}"
  name                = "cluster-msi"
}

resource "azurerm_role_assignment" "cluster_msi_reader" {
  scope                = "${data.azurerm_resource_group.cluster_node_group.id}"
  role_definition_name = "Reader"
  principal_id         = "${azurerm_user_assigned_identity.cluster_msi.principal_id}"
}

resource "azurerm_role_assignment" "cluster_sp_MSI_operator" {
  scope                = "${azurerm_user_assigned_identity.cluster_msi.id}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = "${azurerm_azuread_service_principal.aks_cluster.id}"
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

data "azurerm_kubernetes_cluster" "cluster" {
  name                = "${azurerm_template_deployment.aks_cluster_arm.outputs["cluster_name"]}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
}

data "azurerm_resource_group" "cluster_node_group" {
    name = "${data.azurerm_kubernetes_cluster.cluster.node_resource_group}" 
}
