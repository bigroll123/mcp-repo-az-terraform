data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "mcp_identity" {
  name                = "id-mcp-gateway-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# --- API MANAGEMENT (The Gateway) ---
resource "azurerm_api_management" "apim" {
  name                = "apim-mcp-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mcp_identity.id]
  }
}

# --- API CENTER (The Registry) ---
resource "azapi_resource" "apic" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = "apic-registry-${local.suffix}"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  body = {
    identity = { type = "SystemAssigned" }
    properties = {}
  }
}

# Default Workspace
data "azapi_resource" "default_workspace" {
  type      = "Microsoft.ApiCenter/services/workspaces@2024-03-01"
  name      = "default"
  parent_id = azapi_resource.apic.id
}

resource "azapi_resource" "environment" {
  type      = "Microsoft.ApiCenter/services/workspaces/environments@2024-03-01"
  name      = "production"
  parent_id = data.azapi_resource.default_workspace.id
  
  body = {
    properties = {
      title = "Production"
      kind  = "Production"
      server = {
        type = "Azure API Management"
        managementPortalUri = [azurerm_api_management.apim.developer_portal_url]
      }
    }
  }
}

resource "azapi_resource" "schema_vendor" {
  type      = "Microsoft.ApiCenter/services/metadataSchemas@2024-06-01-preview"
  name      = "vendor"
  parent_id = azapi_resource.apic.id
  body = {
    properties = {
      schema     = jsonencode({ type = "string", title = "Vendor" })
      assignedTo = [{ entity = "api" }]
    }
  }
}