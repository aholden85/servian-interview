resource "azurerm_postgresql_server" "psql" {
    name                = vars.psql_server_name
    location            = vars.location
    resource_group_name = azurerm_resource_group.rg.name

    administrator_login          = vars.psql_login
    # TODO: Implement random password generation.
    administrator_login_password = "H@Sh1CoR3!"

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