output "gateway_endpoint_streamable_http" {
  value     = "${azurerm_api_management.apim.gateway_url}/mslearn/?subscription-key=${azurerm_api_management_subscription.mcp_sub.primary_key}"
  sensitive = true
}

output "gateway_endpoint_sse" {
  value     = "${azurerm_api_management.apim.gateway_url}/mslearn/sse?subscription-key=${azurerm_api_management_subscription.mcp_sub.primary_key}"
  sensitive = true
}

output "aad_client_id" {
  value = azuread_application.mcp_app.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subscription_key" {
  value     = azurerm_api_management_subscription.mcp_sub.primary_key
  sensitive = true
}
