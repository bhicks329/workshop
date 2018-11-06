resource "azurerm_virtual_network" "cluster_virtual_network" {
  name                = "${var.basename}-${var.environment}"
  location            = "${azurerm_resource_group.env_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
  address_space       = ["${var.vnet_address_space}"]
}

resource "azurerm_subnet" "cluster_subnet" {
  name                      = "cluster"
  resource_group_name       = "${azurerm_resource_group.env_resource_group.name}"
  address_prefix            = "${var.cluster_subnet_range}"
  virtual_network_name      = "${azurerm_virtual_network.cluster_virtual_network.name}"
  service_endpoints         = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}


resource "null_resource" "fix_routetable" {
  provisioner "local-exec" {
    command = "az network vnet subnet update -n ${azurerm_subnet.cluster_subnet.name} -g ${azurerm_resource_group.env_resource_group.name} --vnet-name ${azurerm_virtual_network.cluster_virtual_network.name} --route-table $(az resource list --resource-group ${data.azurerm_kubernetes_cluster.cluster.node_resource_group} --resource-type Microsoft.Network/routeTables --query '[].{ID:id}' -o tsv)"
  }
  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}