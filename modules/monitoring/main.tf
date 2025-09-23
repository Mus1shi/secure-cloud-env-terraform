resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-secureenv"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

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
    performance_counter {
      name                          = "perf-linux-basic"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory\\Available MBytes",
        "LogicalDisk(*)\\% Free Space",
        "LogicalDisk(*)\\Disk Reads/sec",
        "LogicalDisk(*)\\Disk Writes/sec",
      ]
    }

    syslog {
      name           = "syslog-auth"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "daemon", "syslog", "user"]
      log_levels     = ["Debug","Info","Notice","Warning","Error","Critical","Alert","Emergency"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["law"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "assoc" {
  name                    = "dcr-assoc-secureenv"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}

resource "azurerm_storage_account" "flowlogs_sa" {
  name                     = "stflow${substr(var.resource_group_name, 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_network_watcher" "nw" {
  name                = "network-watcher-secureenv"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_watcher_flow_log" "flowlog" {
  for_each                       = toset(var.nsg_ids)
  name                           = "flowlog-${substr(each.value, length(each.value)-6, 6)}"
  resource_group_name            = var.resource_group_name
  network_watcher_name           = azurerm_network_watcher.nw.name
  network_security_group_id      = each.value
  storage_account_id             = azurerm_storage_account.flowlogs_sa.id
  enabled                        = true
  version                        = 2

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
