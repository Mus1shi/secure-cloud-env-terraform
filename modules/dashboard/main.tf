data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azapi_resource" "dashboard" {
  type      = "Microsoft.Portal/dashboards@2020-09-01-preview"
  name      = var.dashboard_name
  parent_id = data.azurerm_resource_group.rg.id
  location  = var.location

  # ⬇️ Désactive la validation de schéma côté provider
  schema_validation_enabled = false

  body = jsonencode({
    properties = jsondecode(file("${path.module}/properties.json"))
    tags = {
      project = "secure-cloud-env-terraform"
      env     = "demo"
    }
  })
}