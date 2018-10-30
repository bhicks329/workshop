# module "test_environment" {
#   source = "./environment"

#   environment           = "test"
#   location              = "${var.location}"
#   kubernetes_version    = "${var.kubernetes_version}"
#   vnet_address_space    = "${var.test_vnet_address_space}"
#   admin_usernane        = "${var.admin_username}"
#   basename              = "${var.basename}"
#   cluster_node_count    = "${var.cluster_node_count}"
#   cluster_node_size     = "${var.cluster_node_size}"
#   cluster_os_disk_size  = "${var.cluster_os_disk_size}"
#   cluster_subnet_prefix = "${var.test_cluster_subnet_prefix}"
#   subscription          = "${var.test_sub_id}"
# }