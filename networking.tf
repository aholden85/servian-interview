# Create the virtual network (VNet) for the environment.
resource "azurerm_virtual_network" "prod_vnet" {
  name                = "prod-vnet"
  address_space       = ["192.168.0.0/24"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Create the subnet for the Azure Kubernetes Service (AKS) cluster.
resource "azurerm_subnet" "prod_aks_cluster_subnet" {
  name                 = "prod-aks-cluster-subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.prod_vnet.name}"
  address_prefixes     = ["192.168.0.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Create the ???
resource "azurerm_postgresql_virtual_network_rule" "prod_db_vnet_rule" {
  name                                 = "prod_db_vnet_rule"
  resource_group_name                  = "${azurerm_resource_group.rg.name}"
  server_name                          = "${var.prod_psql_server_name}"
  subnet_id                            = "${azurerm_subnet.prod_aks_cluster_subnet.id}"
  ignore_missing_vnet_service_endpoint = true
}

# Create Network Security Groups to control network access.
resource "azurerm_network_security_group" "inbound_web" {
  name                = "inbound_web"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "inbound_psql" {
  name                = "inbound_psql"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "PostgreSQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "inbound_aks" {
  name                = "inbound_aks"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "Kubernetes"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}