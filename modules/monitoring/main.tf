
# -----------------------------
# Log Analytics Workspace (LAW)
# -----------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-secureenv"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ------------------------------------
# Data Collection Rule (AMA) - minimal
#  - Syslog Linux -> LAW
#  (On ajoutera les perf Linux plus tard si nécessaire)
# ------------------------------------
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "dcr-secureenv"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      name                  = "law"
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
    }
  }

  data_sources {
    syslog {
      name           = "syslog-default"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "daemon", "syslog", "user"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law"]
  }
}

# ------------------------------------
# AMA sur toutes les VMs + association
# ------------------------------------
resource "azurerm_virtual_machine_extension" "ama" {
  for_each                  = toset(var.vm_ids)
  name                      = "AzureMonitorLinuxAgent"
  virtual_machine_id        = each.value
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorLinuxAgent"
  type_handler_version      = "1.30"
  automatic_upgrade_enabled = true
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_assoc" {
  for_each                = toset(var.vm_ids)
  name                    = "assoc-dcr-secureenv"
  target_resource_id      = each.value
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}

# --------------------------------------
# Diagnostic Settings - Key Vault -> LAW
# --------------------------------------
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "diag-kv"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AuditEvent" }

  enabled_metric {
  category = "AllMetrics"
}

}

# --------------------------------------------------
# Activity Log (Subscription) -> LAW (catégories clés)
# (si droits insuffisants au scope subscription, commente ce bloc)
# --------------------------------------------------
data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "sub_activity" {
  name                       = "diag-activity-sub"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "ServiceHealth" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Recommendation" }
  enabled_log { category = "Policy" }
  enabled_log { category = "Autoscale" }
  enabled_log { category = "ResourceHealth" }
}

# -------------------------------------------------------
# Network Watcher existant (1 par région) + Storage Account
# -------------------------------------------------------
data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_westeurope"
  resource_group_name = "NetworkWatcherRG"
}

resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_storage_account" "flowlogs_sa" {
  name                     = "saflow${replace(var.location, "-", "")}${random_string.sa_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# -------------------------------------------------------
# NSG Flow Logs v2 + Traffic Analytics (sur chaque NSG)
# -------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "flowlog" {
  for_each             = var.enable_nsg_flow_logs ? toset(var.nsg_ids) : [] # ← désactivé par défaut
  name                 = "flowlog-${substr(each.value, length(each.value) - 6, 6)}"
  resource_group_name  = data.azurerm_network_watcher.nw.resource_group_name
  network_watcher_name = data.azurerm_network_watcher.nw.name

  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.flowlogs_sa.id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.law.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.law.location
    workspace_resource_id = azurerm_log_analytics_workspace.law.id
    interval_in_minutes   = 10
  }
}

# ---------------------------------------------
# Action Group (option) + Alerte CPU (1 par VM)
# ---------------------------------------------
locals {
  has_email = var.alert_email != null && var.alert_email != ""
  vm_map    = { for idx, id in var.vm_ids : tostring(idx) => id }
}

resource "azurerm_monitor_action_group" "ag" {
  count               = local.has_email ? 1 : 0
  name                = "ag-secureenv"
  resource_group_name = var.resource_group_name
  short_name          = "secenv"

  email_receiver {
    name                    = "owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "cpu_high" {
  for_each            = local.has_email ? local.vm_map : {}
  name                = "cpu-high-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value] # ← 1 VM par alerte
  description         = "CPU > 80% for 5 minutes"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag[0].id
  }
}
