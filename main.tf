terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.114.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "arg" {
  name     = "TaskBoardRG"
  location = "North Europe"
}

resource "azurerm_service_plan" "asp" {
  name                = "TaskBoardSP"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = "TaskBoardkWebApp"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = false
    application_stack {
      dotnet_version = "6.0"
    }
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};User ID=${azurerm_mssql_server.sql.administrator_login};Password=${azurerm_mssql_server.sql.administrator_login_password};Trusted_Connection=False;MultipleActiveResultSets=True;"
  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = "taskboard-sql-001"
  resource_group_name          = azurerm_resource_group.arg.name
  location                     = azurerm_resource_group.arg.location
  version                      = "12.0"
  administrator_login          = "user01"
  administrator_login_password = "@Aa123456789!"
}

resource "azurerm_mssql_database" "db" {
  name           = "TaskBoardSQLDb"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "firewallrule" {
  name             = "TaskBoardFirewallRule"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_app_service_source_control" "aassc" {
  app_id                 = azurerm_linux_web_app.alwa.id
  repo_url               = "https://github.com/ValeriDimov/Azure-Web-App-with-Database-Terraform-TaskBoard"
  branch                 = "main"

  use_manual_integration = true
}
