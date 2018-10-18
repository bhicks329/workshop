resource azurerm_network_security_group "cluster_subnet_nsg" {
  name                = "${var.basename}-${var.environment}-cluster-nsg"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"
}
