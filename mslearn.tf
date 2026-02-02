# --- 1. APIM API Configuration ---
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

  subscription_key_parameter_names {
    query  = "subscription-key"
    header = "Ocp-Apim-Subscription-Key"
  }
}

resource "azurerm_api_management_api_policy" "mcp_policy" {
  api_name            = azurerm_api_management_api.mslearn_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <set-backend-service base-url="https://learn.microsoft.com/api/mcp" />
    </inbound>
    <backend>
        <forward-request timeout="240" buffer-response="false" fail-on-error-status-code="true" />
    </backend>
</policies>
XML
}

# --- 2. API Operations ---
resource "azurerm_api_management_api_operation" "streamable" {
  operation_id        = "post-root"
  api_name            = azurerm_api_management_api.mslearn_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Streamable HTTP"
  method              = "POST"
  url_template        = "/"
}

resource "azurerm_api_management_api_operation" "sse" {
  operation_id        = "get-sse"
  api_name            = azurerm_api_management_api.mslearn_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "SSE Connection"
  method              = "GET"
  url_template        = "/sse"
}

resource "azurerm_api_management_api_operation" "messages" {
  operation_id        = "post-messages"
  api_name            = azurerm_api_management_api.mslearn_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Messages"
  method              = "POST"
  url_template        = "/messages"
}

# --- 3. Access Control ---
resource "azurerm_api_management_product" "mcp_product" {
  product_id          = "mcp"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "MCP Product"
  published             = true
  subscription_required = true
}

resource "azurerm_api_management_product_api" "mcp_product_api" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  product_id          = azurerm_api_management_product.mcp_product.product_id
  api_name            = azurerm_api_management_api.mslearn_proxy.name
}

resource "azurerm_api_management_user" "mcp_user" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  user_id             = "mcp-test-user"
  first_name          = "MCP"
  last_name           = "Client"
  email               = var.apim_user_email
  state               = "active"
}

resource "azurerm_api_management_subscription" "mcp_sub" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "MCP-Roo-Key"
  state               = "active"
  product_id          = azurerm_api_management_product.mcp_product.id
  user_id             = azurerm_api_management_user.mcp_user.id
}

# --- 4. API Center Registration (Stability Fix) ---
resource "azapi_resource" "schema_vendor" {
  type      = "Microsoft.ApiCenter/services/metadataSchemas@2024-03-01"
  name      = "vendor"
  parent_id = azapi_resource.apic.id
  body = { properties = { schema = jsonencode({ type = "string", title = "Vendor" }), assignedTo = [{ entity = "api" }] } }
}

resource "azapi_resource" "schema_category" {
  type      = "Microsoft.ApiCenter/services/metadataSchemas@2024-03-01"
  name      = "category"
  parent_id = azapi_resource.apic.id
  body = { properties = { schema = jsonencode({ type = "string", title = "Category" }), assignedTo = [{ entity = "api" }] } }
}

resource "azapi_resource" "schema_visibility" {
  type      = "Microsoft.ApiCenter/services/metadataSchemas@2024-03-01"
  name      = "visibility"
  parent_id = azapi_resource.apic.id
  body = { properties = { schema = jsonencode({ type = "string", title = "Visibility" }), assignedTo = [{ entity = "api" }] } }
}

resource "azapi_resource" "mcp_api_registration" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-03-01"
  name      = "mslearn-mcp-tool"
  parent_id = data.azapi_resource.default_workspace.id
  
  depends_on = [
    azapi_resource.schema_vendor, 
    azapi_resource.schema_category, 
    azapi_resource.schema_visibility
  ]

  body = {
    properties = {
      title = "Microsoft Learn MCP Server"
      kind  = "Rest"
      customProperties = {
        vendor     = "Microsoft"
        category   = "Education"
        visibility = "true"
      }
    }
  }

  # This helps skip the "identity" check that is failing
  lifecycle {
    ignore_changes = [body.identity]
  }
}

resource "azapi_resource" "api_version" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions@2024-03-01"
  name      = "vv1-0-01"
  parent_id = azapi_resource.mcp_api_registration.id
  body = { properties = { title = "v1", lifecycleStage = "Production" } }
}

resource "azapi_resource" "api_definition" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-03-01"
  name      = "openapi"
  parent_id = azapi_resource.api_version.id
  body = { properties = { title = "OpenAPI Definition" } }
}

resource "azapi_resource" "mcp_deployment" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-03-01"
  name      = "production-gateway"
  parent_id = azapi_resource.mcp_api_registration.id
  body = {
    properties = {
      title = "Production Secured Gateway"
      environmentId = "/workspaces/default/environments/${azapi_resource.environment.name}"
      definitionId  = "/workspaces/default/apis/${azapi_resource.mcp_api_registration.name}/versions/${azapi_resource.api_version.name}/definitions/${azapi_resource.api_definition.name}"
      server        = { runtimeUri = ["${azurerm_api_management.apim.gateway_url}/mslearn"] }
    }
  }
}