variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for API Hub (e.g., europe-west1)."
  type        = string
  default     = "europe-west1"
}

variable "apigee_env_name" {
  description = "The existing Apigee Environment name. (Not used in this config – reserved for future Apigee integration)"
  type        = string
  default     = "dev"
}

variable "publisher_email" {
  description = "Email for the API Owner. (Not used in this config – reserved for future API publisher IAM)"
  type        = string
}
