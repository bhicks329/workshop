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

  # Policy for the Service Principial creating the key vault
  # Review access policies for Service Principial
  access_policy {
    tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    object_id = "${azurerm_user_assigned_identity.cluster_msi.principal_id}"

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

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
}
