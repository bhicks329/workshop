module "mgmt_environment" {
  source             = "./environment"
  location           = "${var.location}"
  basename           = "${var.basename}"
  environment        = "mgmt"
  vnet_address_space = "10.0.0.0/16"
  subscription       = "0aa2ecc4-7253-40a6-8b01-0e9967db87b3"
}
