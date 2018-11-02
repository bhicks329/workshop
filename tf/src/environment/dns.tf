resource "azurerm_dns_zone" "environment_zone" {
  name                = "${var.environment}.${var.basename}.${var.root_dns_zone}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
  zone_type           = "Public"
}

