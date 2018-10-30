module "mgmt_environment" {
  source                = "./environment"
  location              = "${var.location}"
  basename              = "${var.basename}"
  environment           = "mgmt"
  service_address_range = "10.235.0.0/24"
  subscription          = "0aa2ecc4-7253-40a6-8b01-0e9967db87b3"
}
