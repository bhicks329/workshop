# module "dev_environment" {
#   source = "./environment"
  
#   environment           = "dev"
#   basename              = "${var.basename}"

#   kubernetes_version    = "${var.kubernetes_version}"
#   vnet_address_space    = "${var.dev_vnet_address_space}"
#   admin_usernane        = "${var.admin_username}"
#   cluster_node_count    = "${var.cluster_node_count}"
#   cluster_node_size     = "${var.cluster_node_size}"
#   cluster_os_disk_size  = "${var.cluster_os_disk_size}"
#   cluster_subnet_prefix = "${var.cluster_subnet_prefix}"
#   subscription          = "${var.mgmt_sub_id}"
# }