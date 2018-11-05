locals {
  acr_name = "${var.basename}${var.environment}${random_string.acr_suffix.result}"
  acr_formatted_name = "${replace(local.acr_name,"-","")}"
}

resource "random_string" "acr_suffix" {
  length  = 6
  special = false
}

resource "azurerm_container_registry" "acr" {
  name                = "${lower(local.acr_formatted_name)}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
  location            = "${azurerm_resource_group.env_resource_group.location}"
  admin_enabled       = true
  sku                 = "Basic"
}
