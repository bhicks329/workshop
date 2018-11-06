# resource "azurerm_key_vault_secret" "cosmos_db" {
#   name      = "cosmosdb-uri"
#   value     = "${base64encode(azurerm_cosmosdb_account.cosmos.connection_strings[0])}"
#   vault_uri = "${azurerm_key_vault.vault.vault_uri}"
# }

# resource "azurerm_key_vault_secret" "kube_config" {
#   name      = "${var.basename}-${var.environment}-kubeconfig"
#   value     = "${base64encode(data.azurerm_kubernetes_cluster.cluster.kube_config_raw)}"
#   vault_uri = "${azurerm_key_vault.vault.vault_uri}"
# }