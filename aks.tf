# Generate a random password for the Service Principal.
resource "random_password" "sp_password" {
  length  = 24
  special = true
}

# Create a representation of the application with Azure AD. We will later link a Service Principal to this.
resource "azuread_application" "prod_aks_cluster_app" {
  name = "prod-aks-cluster-app"
}

# Create a Service Principal to be used for creating resources, such as the Ingress application gateway.
resource "azuread_service_principal" "prod_aks_cluster_sp" {
  application_id = "${azuread_application.prod_aks_cluster_app.application_id}"
}

# Create a password associated with the Service Principal.
resource "azuread_service_principal_password" "prod_aks_cluster_sp_password" {
  service_principal_id = "${azuread_service_principal.prod_aks_cluster_sp.id}"
  description          = "Password used by Azure Kubernetes Service (AKS)."
  value                = "${random_password.sp_password.result}"

  # How are password rotations handled?
  end_date_relative = "8760h"
}

resource "azuread_group" "prod_aks_cluster_admin_group" {
  name = "prod-aks-cluster-admin-group"
}

resource "azurerm_kubernetes_cluster" "prod_aks_cluster" {
  name                = "${var.prod_aks_cluster_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  dns_prefix          = "${var.prod_aks_dns_prefix}"
  sku_tier            = "Free"

  default_node_pool {
    name            = "default"
    node_count      = var.prod_aks_node_count
    os_disk_size_gb = 32
    vm_size         = "Standard_B2s"
    vnet_subnet_id  = "${azurerm_subnet.prod_aks_cluster_subnet.id}"
    type            = "VirtualMachineScaleSets"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "Standard"
  }

  service_principal {
    client_id     = "${azuread_service_principal.prod_aks_cluster_sp.application_id}"
    client_secret = "${random_password.sp_password.result}"
  }
}

output "prod_k8s_config" {
  value       = "${azurerm_kubernetes_cluster.prod_aks_cluster.kube_config_raw}"
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools."
}