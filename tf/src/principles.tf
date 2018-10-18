#  Create the Prometheus Application and Service Principle
resource "azurerm_azuread_application" "aks_cluster" {
  name                       = "aks-${var.basename}-${var.environment}"
  homepage                   = "https://aks-${var.basename}-${var.environment}"
  identifier_uris            = ["https://aks-${var.basename}-${var.environment}"]
  reply_urls                 = ["https://aks-${var.basename}-${var.environment}"]
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

resource "random_string" "aks_cluster_sp_pass" {
  length  = 16
  special = true
}
