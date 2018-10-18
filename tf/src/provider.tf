terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version = "~> 1.16.0"
}

provider "helm" {
  kubernetes {
    config_path = "${local_file.kubeconfig.filename}"
  }
}