# Generate a random name for the PostgreSQL database server.
resource "random_pet" "pgsql_server_name" {
  length = 2
}

# Generate a random name for the PostgreSQL database.
resource "random_pet" "pgsql_db_name" {
  length = 1
}

# Generate a random password for the PostgreSQL database Administrator login.
resource "random_password" "pgsql_password" {
  length  = 24
  special = true
}

# Create the PostgreSQL server.
resource "azurerm_postgresql_server" "pgsql_server" {
  name                = random_pet.pgsql_server_name.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login = var.pgsql_server_login
  administrator_login_password = random_password.pgsql_password.result

  sku_name   = "GP_Gen5_4"
  version    = "9.6"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  # This value had to be set to true to create the database in a Free account.
  public_network_access_enabled    = true

  # Without this variable set to false, the database seed function failed to connect to the database.
  ssl_enforcement_enabled          = false
}

# Create a database on the PostgreSQL server.
resource "azurerm_postgresql_database" "pgsql_db" {
  name                = random_pet.pgsql_db_name.id
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.pgsql_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}