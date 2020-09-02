# Generate a random password for the PostgreSQL database Administrator login.
resource "random_password" "prod_psql_password" {
  length  = 24
  special = true
}

resource "azurerm_postgresql_server" "prod_psql_server" {
  name                = var.prod_psql_server_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login = var.prod_psql_server_login

  # This password will be stored in state as a plaintext string.
  administrator_login_password = random_password.prod_psql_password.result

  sku_name   = "GP_Gen5_4"
  version    = "9.6"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}