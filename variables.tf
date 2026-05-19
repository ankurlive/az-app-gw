variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be created."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "client_id" {
  type        = string
  description = "App registration (service principal) application (client) ID."
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "App registration client secret."
}
