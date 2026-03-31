data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azuread_application" "mcp_app" {
  display_name = "mcp-gateway-app-${local.suffix}"
  owners       = [data.azurerm_client_config.current.object_id]
  identifier_uris = ["api://mcp-gateway-${local.suffix}"]

  api {
    requested_access_token_version = 2
    oauth2_permission_scope {
      admin_consent_display_name = "Access MCP Gateway"
      admin_consent_description  = "Allows the app to access the MCP Gateway as the signed-in user."
      user_consent_display_name  = "Access MCP Gateway"
      user_consent_description   = "Allow the application to access the MCP Gateway on your behalf."
      id                         = "96183846-204b-4b43-82e1-5d2222eb4b9b"
      enabled                    = true
      type                       = "User"
      value                      = "access_as_user"
    }
  }
}

resource "azuread_service_principal" "mcp_sp" {
  client_id = azuread_application.mcp_app.client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "mcp_secret" {
  application_id = azuread_application.mcp_app.id
}

resource "azurerm_api_management" "apim" {
  name                = "apim-mcp-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"
}

resource "azurerm_api_management_identity_provider_aad" "aad" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  client_id           = azuread_application.mcp_app.client_id
  client_secret       = azuread_application_password.mcp_secret.value
  allowed_tenants     = [data.azurerm_client_config.current.tenant_id]
}

resource "terraform_data" "always_change" {
  input = timestamp()
}

resource "azapi_resource" "apic" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = "apic-registry-${local.suffix}"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  body      = { identity = { type = "SystemAssigned" } }
}

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
      title = "Production Environment"
      kind  = "Production"
    }
  }
}