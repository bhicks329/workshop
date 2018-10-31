resource "azurerm_virtual_network" "cluster_virtual_network" {
  name                = "${var.basename}-${var.environment}"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"
  address_space       = ["${var.vnet_address_space}"]
}

resource "azurerm_subnet" "cluster_subnet" {
  name                      = "cluster"
  resource_group_name       = "${azurerm_resource_group.aks_resource_group.name}"
  address_prefix            = "${var.cluster_subnet_range}"
  virtual_network_name      = "${azurerm_virtual_network.cluster_virtual_network.name}"
  service_endpoints         = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}
