# --- 1. APIM API PROXY ---
resource "azurerm_api_management_api" "mslearn_proxy" {
  name                = "mslearn-mcp"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Microsoft Learn MCP"
  path                = "mslearn"
  protocols           = ["https"]
  service_url         = "https://learn.microsoft.com/api/mcp"
  subscription_required = true

  import {
    content_format = "openapi"
    content_value  = jsonencode({
      openapi = "3.0.1"
      info = {
        title       = "MSLearn MCP Proxy"
        version     = "1.0"
        description = "MCP-compliant gateway for Microsoft Learn documentation tools."
      }
      paths = {
        "/mcp" = {
          post = {
            operationId = "mcp-rpc-handler"
            summary     = "MCP JSON-RPC Gateway"
            responses   = { "200" = { description = "Success" } }
          }
        }
      }
    })
  }
}

# --- 2. AUTHENTICATION POLICY ---
# This injects the Managed Identity token so APIM can talk to the backend securely
resource "azurerm_api_management_api_policy" "mcp_auth_policy" {
  api_name            = azurerm_api_management_api.mslearn_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <authentication-managed-identity 
            resource="https://management.azure.com/" 
            client-id="${azurerm_user_assigned_identity.mcp_identity.client_id}" 
            output-token-variable-name="msi-access-token" 
            ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + context.Variables.GetValueOrDefault<string>("msi-access-token"))</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}

# --- 3. PRODUCT & SUBSCRIPTION ---
resource "azurerm_api_management_product" "mcp_product" {
  product_id            = "mcp-suite"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "AI Agent MCP Suite"
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "mcp_product_api" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  product_id          = azurerm_api_management_product.mcp_product.product_id
  api_name            = azurerm_api_management_api.mslearn_proxy.name
}

resource "azurerm_api_management_subscription" "mcp_sub" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "MCP Access Key"
  product_id          = azurerm_api_management_product.mcp_product.id
  state               = "active"
}

# --- 4. API CENTER REGISTRATION (Discovery) ---
resource "azapi_resource" "mcp_api_registration" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-06-01-preview"
  name      = "mslearn-mcp-tool"
  parent_id = data.azapi_resource.default_workspace.id
  
  body = {
    properties = {
      title       = "Microsoft Learn MCP Server"
      kind        = "mcp"
      description = "Official Microsoft Learn tools for AI agents."
      customProperties = {
        vendor = "Microsoft"
      }
    }
  }
  depends_on = [azapi_resource.schema_vendor]
}

resource "azapi_resource" "api_version" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions@2024-06-01-preview"
  name      = "v1-0-0"
  parent_id = azapi_resource.mcp_api_registration.id
  body      = { properties = { title = "v1", lifecycleStage = "production" } }
}

resource "azapi_resource" "api_definition" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-06-01-preview"
  name      = "mcp-openapi"
  parent_id = azapi_resource.api_version.id
  body = {
    properties = {
      title       = "MCP OpenAPI Spec"
      description = "The technical specification for the MCP proxy."
    }
  }
}
resource "azapi_resource" "mcp_deployment" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-06-01-preview"
  name      = "production-gateway"
  parent_id = azapi_resource.mcp_api_registration.id
  body = {
    properties = {
      title = "Production Secured Gateway"

      environmentId = "/workspaces/${data.azapi_resource.default_workspace.name}/environments/${azapi_resource.environment.name}"

      definitionId = "/workspaces/${data.azapi_resource.default_workspace.name}/apis/${azapi_resource.mcp_api_registration.name}/versions/${azapi_resource.api_version.name}/definitions/${azapi_resource.api_definition.name}"

      server = {
        runtimeUri = ["${azurerm_api_management.apim.gateway_url}/mslearn/mcp"]
      }
      state = "active"
    }
  }
}