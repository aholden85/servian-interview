resource "azurerm_kubernetes_cluster" "aks" {
    name                = vars.k8s_cluster_name
    location            = vars.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = var.k8s_dns_prefix
    sku_tier            = "Free"

    default_node_pool {
        name                  = "default"
        node_count            = vars.k8s_node_count
        vm_size               = "Standard_DS2_v2"
        vnet_subnet_id        = azurerm_subnet.k8s.id
    }

    identity {
        type = "SystemAssigned"
    }
}