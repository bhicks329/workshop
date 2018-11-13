variable "environment" {
  type = "string"
}

variable "basename" {
  type = "string"
}

variable "location" {
  type = "string"
}
variable "app_url" {
  type = "list"
  default = []
}
variable "branch_name" {
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

variable "wrregistry_username" {
  type    = "string"
  default = "warroommaster"
}
variable "wrregistry_passwd" {
  type    = "string"
  default = "OzvWnaX4DVWHQlxuZp7Yq+WAjwKKg8K3"
}

variable "wrregistry_url" {
  type    = "string"
  default = "warroommaster.azurecr.io"
}

variable "wrregistry_helm" {
  type    = "string"
  default = "warroommaster"
}

variable "wrregistry_sub" {
  type    = "string"
  default = "8d7951f6-ff12-4e36-822b-cdba7dca0469"
}

variable "cluster_node_count" {
  type    = "string"
  default = "2"
}

variable "cluster_node_size" {
  type    = "string"
  default = "Standard_E2s_v3"
}

variable "kubernetes_version" {
  type    = "string"
  default = "1.11.3"
}

variable "subscription" {
  type = "string"
}

variable "cluster_subnet_range" {
  type = "string"
}

variable "service_address_range" {
  type = "string"
}

variable "vnet_address_space" {
  type = "string"
}

variable "is_mgmt" {
  type    = "string"
  default = "0"
}

variable "istio-version" {
  type = "string"
  default = "1.0.3"
}

variable "root_dns_zone" {
  type = "string"
  default = "demo.sequenced.net"
}

variable "aquasec_scan_username" {
  type = "string"
  default  = "scanner"
}

variable "aquasec_scan_password" {
  type = "string"
  default  = "myscan77"
}

variable "aquasec_admin_username" {
  type = "string"
  default  = "administrator"
}

variable "aquasec_admin_password" {
  type = "string"
  default  = "myadmin77"
}