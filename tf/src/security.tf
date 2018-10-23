resource azurerm_network_security_group "cluster_subnet_nsg" {
  name                = "${var.basename}-${var.environment}-cluster-nsg"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"

  security_rule {
    name                       = "allowJenkins"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
