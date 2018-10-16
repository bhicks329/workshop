locals {
  acr_name = "${var.basename}${var.environment}${random_string.acr_suffix.result}"
}

resource "random_string" "acr_suffix" {
  length  = 6
  special = false
}
resource "azurerm_container_registry" "acr" {
  name                = "${lower(local.acr_name)}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  admin_enabled       = true
  sku                 = "Basic"
}