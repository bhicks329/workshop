variable "environment" {
  type = "string"
}

variable "basename" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "vnet_address_space" {
  type = "string"
}

variable "admin_username" {
  type    = "string"
  default = "azureadmin"
}

variable "cluster_os_disk_size" {
  type    = "string"
  default = "100"
}

variable "cluster_node_count" {
  type    = "string"
  default = 2
}

variable "cluster_node_size" {
  type    = "string"
  default = "Standard_DS2_v2"
}

variable "kubernetes_version" {
  type    = "string"
  default = "1.11.3"
}

variable "subscription" {
  type = "string"
}
