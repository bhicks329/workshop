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


# resource "helm_release" "jenkins" {
#     name      = "jenkins"
#     chart     = "stable/jenkins"

#     set {
#         name  = "name"
#         value = "jenkins"
#     }

#     set {
#         name = "namespace"
#         value = "devops"
#     }
#     depends_on = ["null_resource.helm_init"]
# }
