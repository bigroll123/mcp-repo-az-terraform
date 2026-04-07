output "mcp_gateway_sa_email" {
  description = "The Service Account email Apigee uses to talk to backend."
  value       = google_service_account.mcp_gateway_sa.email
}
/*
output "mcp_api_key" {
  description = "The API Key for your AI Agent."
  value       = google_apigee_developer_app.mcp_app.credentials[0].consumer_key
  sensitive   = true
}

output "api_hub_registry_id" {
  description = "The ID of the registered MCP API"
  value       = google_apihub_api.mcp_tool_registration.id
}
*/
