resource "null_resource" "register_ms_learn" {
  provisioner "local-exec" {
    command = <<EOT
      # 1. API (Use || true because it was created in the last run)
      gcloud alpha apihub apis create \
        --api="microsoft-learn-mcp" \
        --display-name="Microsoft Learn MCP" \
        --location="europe-west1" \
        --project="${var.project_id}" || true

      # 2. Deployment (Adding mandatory --endpoints and --resource-uri)
      # We use a standard system-defined deployment type ID
      gcloud alpha apihub deployments create "ms-learn-endpoint" \
        --display-name="MS Learn Endpoint" \
        --location="europe-west1" \
        --project="${var.project_id}" \
        --endpoints="https://learn.microsoft.com/api/mcp" \
        --resource-uri="https://learn.microsoft.com/api/mcp" \
        --deployment-type-uri-values="projects/${var.project_id}/locations/europe-west1/attributes/system-deployment-type/enumValues/manual"

      # 3. Version (Changing ID to 'version-1' to satisfy the ID validator)
      gcloud alpha apihub apis versions create "version-1" \
        --api="microsoft-learn-mcp" \
        --display-name="Version 1.0" \
        --location="europe-west1" \
        --project="${var.project_id}"

      # 4. Link Version to Deployment
      gcloud alpha apihub apis versions update "version-1" \
        --api="microsoft-learn-mcp" \
        --location="europe-west1" \
        --project="${var.project_id}" \
        --deployments="projects/${var.project_id}/locations/europe-west1/deployments/ms-learn-endpoint"
    EOT
  }

  depends_on = [google_apihub_api_hub_instance.main]
}
