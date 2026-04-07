resource "google_project_service" "apihub" {
  project            = var.project_id
  service            = "apihub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "discovery_engine" {
  project            = var.project_id
  service            = "discoveryengine.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Optional but recommended for API Hub's runtime
resource "google_project_service" "cloud_resource_manager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  suffix = random_string.suffix.result
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

resource "google_apihub_api_hub_instance" "main" {
  project  = var.project_id
  location = var.region

  config {
    encryption_type = "GMEK"
    vertex_location = "eu"      # Vertex AI location for semantic search
    # disable_search = false    # optional, defaults to false
  }

  depends_on = [
    google_project_service.apihub,
    google_project_service.discovery_engine, # needed for semantic search
  ]
}

resource "google_apihub_host_project_registration" "main" {
  provider = google-beta
  project  = var.project_id
  location = "global"                    # must be "global"
  host_project_registration_id = var.project_id
  gcp_project                  = "projects/${var.project_id}"

  depends_on = [
    google_project_service.apihub,
    google_apihub_api_hub_instance.main, # host registration needs the instance
  ]
}
