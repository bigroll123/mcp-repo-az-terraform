output "mcp_gateway_url" {
  description = "The Primary MCP Endpoint for AI Clients."
  value       = "${azurerm_api_management.apim.gateway_url}/mslearn/mcp"
}

output "mcp_subscription_key" {
  description = "The API Key to access the MCP Gateway."
  value       = azurerm_api_management_subscription.mcp_sub.primary_key
  sensitive   = true
}

output "api_center_id" {
  description = "The Resource ID of the API Center Registry."
  value       = azapi_resource.apic.id
}