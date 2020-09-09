# Generate a random password for the Service Principal.
resource "random_password" "aks_sp" {
  length  = 24
  special = true
}

# Create a representation of the application with Azure AD. We will later link a Service Principal to this.
resource "azuread_application" "aks_sp" {
  name = var.app_name
}

# # Do we need this?
# resource "azuread_group" "admin_group" {
#   name = var.admin_group_name
# }

# Create a Service Principal to be used for creating resources, such as the Ingress application gateway.
resource "azuread_service_principal" "aks_sp" {
  application_id               = azuread_application.aks_sp.application_id
  app_role_assignment_required = false
}

# Create a password associated with the Service Principal.
resource "azuread_service_principal_password" "aks_sp" {
  service_principal_id = azuread_service_principal.aks_sp.id
  value                = random_password.aks_sp.result
  end_date_relative    = "8760h" # 1 year
}

# Create a password associated with the Application.
resource "azuread_application_password" "aks_sp" {
  application_object_id = azuread_application.aks_sp.id
  value                 = random_password.aks_sp.result
  end_date_relative     = "8760h" # 1 year
}