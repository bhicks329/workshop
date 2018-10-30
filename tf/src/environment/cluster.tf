# resource "tls_private_key" "cluster_private_key" {
#   algorithm = "RSA"
#   rsa_bits  = "2048"
# }

# resource "azurerm_kubernetes_cluster" "aks_cluster_1" {
#   name                = "${var.basename}-${var.environment}"
#   location            = "${azurerm_resource_group.aks_resource_group.location}"
#   dns_prefix          = "${var.basename}-${var.environment}"
#   kubernetes_version  = "${var.kubernetes_version}"
#   resource_group_name = "${azurerm_resource_group.aks_resource_group.name}"

#   linux_profile {
#     admin_username = "${var.admin_username}"

#     ssh_key {
#       key_data = "${tls_private_key.cluster_private_key.public_key_openssh }"
#     }
#   }

#   agent_pool_profile {
#     name            = "agentpool"
#     count           = "2"
#     vm_size         = "Standard_F2s_v2"
#     os_type         = "Linux"
#     os_disk_size_gb = "${var.cluster_os_disk_size}"

#     # Required for advanced networking
#     vnet_subnet_id = "${azurerm_subnet.cluster_subnet.id}"
#   }

#   service_principal {
#     client_id     = "${data.azurerm_key_vault_secret.clientId.value}"
#     client_secret = "${data.azurerm_key_vault_secret.password.value}"
#   }

#   network_profile {
#     network_plugin     = "azure"
#     service_cidr       = "10.0.0.0/16"
#     docker_bridge_cidr = "172.17.0.1/16"
#     dns_service_ip     = "10.0.0.10"
#   }
# }