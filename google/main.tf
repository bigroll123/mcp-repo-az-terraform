resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  suffix = random_string.suffix.result
  apigee_org_id = "organizations/${var.project_id}"
}

resource "google_service_account" "mcp_gateway_sa" {
  account_id   = "sa-mcp-gateway-${local.suffix}"
  display_name = "MCP Gateway Identity"
  description  = "Identity used by Apigee to invoke MCP Backends"
}

resource "google_project_iam_member" "invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.mcp_gateway_sa.email}"
}


resource "google_apihub_api_hub_instance" "main" {
  project  = var.project_id
  location = "europe-west1"

  config {
    encryption_type   = "GMEK"
    vertex_location   = "eu"
    # disable_search = false 
  }

  depends_on = [
    google_project_service.apihub
  ]
}

resource "google_apihub_host_project_registration" "main" {
  provider                     = google-beta
  project                      = var.project_id
  location                     = "global" 
  host_project_registration_id = var.project_id
  gcp_project                  = "projects/${var.project_id}"

  depends_on = [
    google_project_service.apihub
  ]
}

resource "google_project_iam_member" "apihub_viewer" {
  project = var.project_id
  role    = "roles/apihub.viewer"
  member  = "serviceAccount:${google_service_account.mcp_gateway_sa.email}"
}

resource "google_project_iam_member" "discovery_engine_viewer" {
  project = var.project_id
  role    = "roles/discoveryengine.viewer"
  member  = "serviceAccount:${google_service_account.mcp_gateway_sa.email}"
}
