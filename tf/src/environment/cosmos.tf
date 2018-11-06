resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-${lower(var.basename)}-${lower(var.environment)}-${random_integer.ri.result}"
  location            = "${azurerm_resource_group.env_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.env_resource_group.name}"
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

#   geo_location {
#     location          = "${var.failover_location}"
#     failover_priority = 1
#   }

  geo_location {
    prefix            = "cosmos-${lower(var.basename)}-${lower(var.environment)}-${random_integer.ri.result}-customid"
    location          = "${azurerm_resource_group.env_resource_group.location}"
    failover_priority = 0
  }
}