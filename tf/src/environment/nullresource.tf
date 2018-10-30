#resource "null_resource" "copy_kubeconfig" {
#  provisioner "local-exec" {
#    command = <<EOT
#        cp kubeconfig ~/.kube/config
#        ls ~/.kube
#    EOT
#  }
#  depends_on = ["local_file.kubeconfig"]
#}

# resource "null_resource" "helm_init" {
#   provisioner "local-exec" {
#     command = <<EOT
#        helm init 
#     EOT
#   }
#   depends_on = ["local_file.kubeconfig"]
# }

