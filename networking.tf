# Create the virtual network (VNet) for the environment.
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the subnet for the Azure Kubernetes Service (AKS) cluster.
resource "azurerm_subnet" "aks_cluster_subnet" {
  name                 = "aks-cluster-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Create the access rule to allow traffic from the AKS cluster to the database.
resource "azurerm_postgresql_virtual_network_rule" "db_vnet_rule" {
  name                                 = "db-vnet-rule"
  resource_group_name                  = azurerm_resource_group.rg.name
  server_name                          = azurerm_postgresql_server.pgsql_server.name
  subnet_id                            = azurerm_subnet.aks_cluster_subnet.id
  ignore_missing_vnet_service_endpoint = true
}