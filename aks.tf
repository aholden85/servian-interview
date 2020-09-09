# Create an Azure Kubernetes Cluster to 'house' the k8s job and deployment.
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_prefix
  sku_tier            = "Free"

  default_node_pool {
    name            = "default"
    node_count      = var.aks_node_count
    os_disk_size_gb = 32
    vm_size         = "Standard_B2s"
    vnet_subnet_id  = azurerm_subnet.aks_cluster_subnet.id
    type            = "VirtualMachineScaleSets"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "Standard"
  }

  # We need to assign a service principal to the Azure K8s Cluster to allow it to CRUD resources.
  service_principal {
    client_id     = azuread_service_principal.aks_sp.application_id
    client_secret = random_password.aks_sp.result
  }
}