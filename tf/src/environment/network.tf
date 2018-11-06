resource "azurerm_virtual_network" "cluster_virtual_network" {
  name                = "${var.basename}-${var.environment}"
  location            = "${azurerm_resource_group.env_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
  address_space       = ["${var.vnet_address_space}"]
}

resource "azurerm_subnet" "cluster_subnet" {
  name                 = "cluster"
  resource_group_name  = "${azurerm_resource_group.env_resource_group.name}"
  address_prefix       = "${var.cluster_subnet_range}"
  virtual_network_name = "${azurerm_virtual_network.cluster_virtual_network.name}"
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}

resource "null_resource" "fix_routetable" {
  # Horrible hack to re-apply the subnet routing - Shame!
  triggers {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "az network vnet subnet update -n ${azurerm_subnet.cluster_subnet.name} -g ${azurerm_resource_group.env_resource_group.name} --vnet-name ${azurerm_virtual_network.cluster_virtual_network.name} --route-table $(az resource list --resource-group ${data.azurerm_kubernetes_cluster.cluster.node_resource_group} --resource-type Microsoft.Network/routeTables --query '[].{ID:id}' -o tsv)"
  }

  depends_on = ["azurerm_template_deployment.aks_cluster_arm"]
}

# data "azurerm_route_table" "test" {
#   name                = ""
#   resource_group_name = "some-resource-group"
# }


# resource "azurerm_subnet_route_table_association" "test" {
#   subnet_id      = "${azurerm_subnet.test.id}"
#   route_table_id = "${azurerm_route_table.test.id}"
# }

