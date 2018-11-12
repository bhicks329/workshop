module "mgmt_environment" {
  source                = "./environment"
  location              = "${var.location}"
  basename              = "${var.basename}"
  environment           = "mgmt"
  vnet_address_space    = "10.10.0.0/16"
  cluster_subnet_range  = "10.10.0.0/22"
  service_address_range = "10.10.4.0/22"
  subscription          = "8d7951f6-ff12-4e36-822b-cdba7dca0469"
  is_mgmt               = "1"
  app_url               = ["https://github.com/irinatsyganok/hello_hapi", "https://github.com/irinatsyganok/hello_hapi2"]
  branch_name           = "master"
}

# module "dev_environment" {
#   source                = "./environment"
#   location              = "${var.location}"
#   basename              = "${var.basename}"
#   environment           = "dev"
#   vnet_address_space    = "10.11.0.0/16"
#   cluster_subnet_range  = "10.11.0.0/22"
#   service_address_range = "10.11.4.0/22"
#   subscription          = "0aa2ecc4-7253-40a6-8b01-0e9967db87b3"
# }

# module "test_environment" {
#   source                = "./environment"
#   location              = "${var.location}"
#   basename              = "${var.basename}"
#   environment           = "test"
#   vnet_address_space    = "10.12.0.0/16"
#   cluster_subnet_range  = "10.12.0.0/22"
#   service_address_range = "10.12.4.0/22"
#   subscription          = "0aa2ecc4-7253-40a6-8b01-0e9967db87b3"
# }

# module "prod_environment" {
#   source                = "./environment"
#   location              = "${var.location}"
#   basename              = "${var.basename}"
#   environment           = "prod"
#   vnet_address_space    = "10.13.0.0/16"
#   cluster_subnet_range  = "10.13.0.0/22"
#   service_address_range = "10.13.4.0/22"
#   subscription          = "0aa2ecc4-7253-40a6-8b01-0e9967db87b3"
# }
