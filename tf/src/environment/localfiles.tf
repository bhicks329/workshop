# resource "local_file" "kubeconfig" {
#     content     = "${azurerm_kubernetes_cluster.aks_cluster_1.kube_config_raw}"
#     filename = "${var.home_dir}/.kube/config"
# }