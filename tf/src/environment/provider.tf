terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version = "~> 1.16.0"
}

provider "azurerm" {
  client_id = "${azurerm_azuread_application.terraform_sp.id}"
  client_secret = "${random_string.terraform_sp_pass.result}"
  version = "~> 1.16.0"
  alias = "sp"
}

# provider "helm" {
#   kubernetes {
#     config_path = "${local_file.kubeconfig.filename}"
#   }
# }