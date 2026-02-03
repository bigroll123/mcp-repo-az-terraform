variable "subscription_id" {
  description = "The Azure Subscription ID."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-mcp-gateway"
}

variable "location" {
  description = "The Azure region to deploy to."
  type        = string
  default     = "West Europe"
}

variable "publisher_name" {
  description = "The name of your organization/publisher for APIM."
  type        = string
  default     = "Contoso AI"
}

variable "publisher_email" {
  description = "The email address for APIM notifications."
  type        = string
}