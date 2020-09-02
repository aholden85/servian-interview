# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "servian-interview"
  location = "${var.location}"
}