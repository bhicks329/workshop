locals {
  vault_name = "${lower(var.basename)}${lower(var.environment)}${random_string.vault_suffix.result}"
}

data "azurerm_client_config" "current" {}

resource "random_string" "vault_suffix" {
  length  = 4
  special = false
}

resource "azurerm_key_vault" "vault" {
  name                        = "${format("%.20s", local.vault_name)}"
  location                    = "${azurerm_resource_group.env_resource_group.location}"
  resource_group_name         = "${azurerm_resource_group.env_resource_group.name}"
  enabled_for_disk_encryption = false
  enabled_for_deployment      = false

  sku {
    name = "standard"
  }

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
}

resource "azurerm_key_vault_access_policy" "msi_access" {
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${azurerm_key_vault.vault.resource_group_name}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.cluster_msi.principal_id}"

  key_permissions = []

  secret_permissions = [
    "get",
  ]
}

resource "azurerm_key_vault_access_policy" "user_access" {
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${azurerm_key_vault.vault.resource_group_name}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${data.azurerm_client_config.current.client_id}"

  key_permissions = []

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set",
  ]
}
