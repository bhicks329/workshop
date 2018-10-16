# resource "null_resource" "helm_init" {
#   triggers {
#     aks_cluster = "${azurerm_kubernetes_cluster.aks_cluster_1.fqdn}"
#   }

#   provisioner "local-exec" {
#     command = ""
#   }
# }

# resource "kubernetes_pod" "test" {
#   metadata {
#     name = "terraform-example"
#   }

#   spec {
#     container {
#       image = "nginx:1.7.9"
#       name  = "example"
#     }
#   }
# }