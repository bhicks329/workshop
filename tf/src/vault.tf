locals {
  vault_name = "${random_string.vault_prefix.result}${var.basename}${var.environment}"
}

data "azurerm_client_config" "current" {}

resource "random_string" "vault_prefix" {
  length  = 4
  special = false
}

resource "azurerm_key_vault" "vault" {
  name                        = "${format("%.20s", local.vault_name)}"
  location                    = "${azurerm_resource_group.aks_resource_group.location}"
  resource_group_name         = "${azurerm_resource_group.aks_resource_group.name}"
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true

  sku {
    name = "standard"
  }

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"

  
  # Policy for the Service Principial creating the key vault
  # Review access policies for Service Principial
  access_policy {
    tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

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

  tags {
    environment = "infrastructure"
  }
}
