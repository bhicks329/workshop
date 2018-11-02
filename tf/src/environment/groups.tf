resource "azurerm_resource_group" "env_resource_group" {
  name     = "${var.basename}-${var.environment}"
  location = "${var.location}"
}
