resource "azurerm_resource_group" "aks_resource_group" {
  name     = "${var.basename}-${var.environment}"
  location = "${var.location}"
}
