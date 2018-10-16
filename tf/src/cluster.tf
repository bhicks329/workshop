resource "tls_private_key" "cluster_private_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "azurerm_kubernetes_cluster" "aks_cluster_1" {
  name                = "${var.basename}-${var.environment}"
  location            = "${azurerm_resource_group.aks_resource_group.location}"
  dns_prefix          = "${var.basename}-${var.environment}"
  kubernetes_version  = "${var.kubernetes_version}"
  resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${tls_private_key.cluster_private_key.public_key_openssh }"
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "1"
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = "${var.cluster_os_disk_size}"

    # Required for advanced networking
    vnet_subnet_id = "${azurerm_subnet.cluster_subnet.id}"
  }

  service_principal {
    client_id     = "${azurerm_azuread_application.aks_cluster.application_id}"
    client_secret = "${random_string.aks_cluster_sp_pass.result}"
  }

  network_profile {
    network_plugin = "azure"
  }
}
