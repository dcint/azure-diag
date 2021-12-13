data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "rg" {
  name = "${var.prefix}-rg"
  location = "eastus"
}

resource "azurerm_app_service_plan" "app-plan" {
    name = "${var.prefix}-plan"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    sku {
      tier = "Standard"
      size = "S1"
    }
}

resource "azurerm_log_analytics_workspace" "ws" {
    name = "${var.prefix}-ws"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_monitor_diagnostic_setting" "app-plan-diag" {
  name               = "${var.prefix}-plan-diag"
  target_resource_id = resource.azurerm_app_service_plan.app-plan.id
  log_analytics_workspace_id = resource.azurerm_log_analytics_workspace.ws.id
  

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}

resource "azurerm_storage_account" "st" {
    name = "dcdiagst"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "st-diag" {
  name               = "${var.prefix}-st-diag"
  target_resource_id = resource.azurerm_storage_account.st.id
  log_analytics_workspace_id = resource.azurerm_log_analytics_workspace.ws.id
   

  metric {
    category = "Transaction"

    retention_policy {
     enabled = true
    } 
  }
}

resource "azurerm_function_app" "func" {
  name                       = "${var.prefix}-func"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.app-plan.id
  storage_account_name = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  version = "~3"
}

resource "azurerm_monitor_diagnostic_setting" "func-diag" {
  name               = "${var.prefix}-func-diag"
  target_resource_id = resource.azurerm_function_app.func.id
  log_analytics_workspace_id = resource.azurerm_log_analytics_workspace.ws.id
   

  log {
    category = "FunctionAppLogs"

    retention_policy {
     enabled = true
    } 
  }


  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_monitor_diagnostic_setting" "kv-diag" {
  name               = "${var.prefix}-kv-diag"
  target_resource_id = resource.azurerm_key_vault.kv.id
  log_analytics_workspace_id = resource.azurerm_log_analytics_workspace.ws.id
  
log {
    category = "AuditEvent"

    retention_policy {
     enabled = true
    } 
  }

  log {
    category = "AzurePolicyEvaluationDetails"

    retention_policy {
     enabled = true
    } 
  }

metric {
   category = "AllMetrics"

    retention_policy {
     enabled = true
   }
 }
}