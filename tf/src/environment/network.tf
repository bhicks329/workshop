resource "azurerm_virtual_network" "cluster_virtual_network" {
  name                = "${var.basename}-${var.environment}"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"
  address_space       = ["${var.vnet_address_space}"]
}

resource "azurerm_subnet" "cluster_subnet" {
  name                      = "cluster"
  resource_group_name       = "${azurerm_resource_group.aks_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.cluster_subnet_nsg.id}"
  address_prefix            = "${cidrsubnet(var.vnet_address_space, 8, 0)}"
  virtual_network_name      = "${azurerm_virtual_network.cluster_virtual_network.name}"
}
