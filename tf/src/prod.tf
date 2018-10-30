# module "prod_environment" {
#   source = "./environment"

#   environment           = "prod"
#   location              = "${var.location}"
#   kubernetes_version    = "${var.kubernetes_version}"
#   vnet_address_space    = "10.0.0.0/16"
#   admin_usernane        = "${var.admin_username}"
#   basename              = "${var.basename}"
#   cluster_node_count    = "2"
#   cluster_node_size     = "${var.cluster_node_size}"
#   cluster_os_disk_size  = "${var.cluster_os_disk_size}"
#   cluster_subnet_prefix = "10.0.0.0/24"
#   subscription          = "${var.prod_sub_id}"
# }
