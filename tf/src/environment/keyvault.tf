#variable "basename" {
#  default = "lbg"
#}
#
#variable "environment" {
#  default = "test"
#}

# data "azurerm_resource_group" "kv_resource_group" {
#   name = "mgmt-${var.basename}-${var.environment}"
# }

# data "azurerm_key_vault" "cluster_keyvault" {
#   name                = "${var.basename}${var.environment}${substr(md5("${var.basename}${var.environment}"), 0, 4)}"
#   resource_group_name = "${data.azurerm_resource_group.kv_resource_group.name}"
# }

# data "azurerm_key_vault_secret" "clientId" {
#   name      = "sp-aks-terraform-${var.basename}-${var.environment}-clientId"
# #  name      = "sp-terraform-${var.basename}-${var.environment}-subscriptionId"
#   vault_uri = "${data.azurerm_key_vault.cluster_keyvault.vault_uri}"
# }

# data "azurerm_key_vault_secret" "password" {
#   name      = "sp-aks-terraform-${var.basename}-${var.environment}-password"
#   vault_uri = "${data.azurerm_key_vault.cluster_keyvault.vault_uri}"
# }

#output "vault_uri" {
#  value = "${data.azurerm_key_vault.cluster_keyvault.vault_uri}"
#}
#
#output "vault_value" {
#  value = "${data.azurerm_key_vault_secret.mykey.value}"
#}
