variable "resource_group_name" {
  description = "The name of the Resource Group"
}

variable "location" {
  description = "The location where resources will be created"
}

variable "appgw" {
  type = object({
    subnet_id    = string
    private_ip   = string
    sku_capacity = number
  })
  description = "Application Gateway configuration"
}

variable "is_public" {
  type        = bool
  description = "Whether the Application Gateway is public facing"
  default     = false
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "instance_number" {
  type        = string
  description = "Instance number"
}

variable "sku" {
  type        = string
  description = "SKU type"
  default     = "WAF_v2"
}

variable "enable_http2" {
  type        = bool
  description = "Enable HTTP2"
  default     = false
}

variable "enable_autoscale" {
  type        = bool
  description = "Autoscale enabled"
  default     = false
}

variable "autoscale_min_capacity" {
  type        = number
  description = "Minimum autoscale units"
  default     = 0
}

variable "autoscale_max_capacity" {
  type        = number
  description = "Maximum autoscale units"
  default     = 10
}

variable "trusted_root_certificate" {
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "ssl_certificates" {
  type = list(object({
    name                = string
    key_vault_secret_id = string
  }))
  default = []
}

variable "rewrite_rule_sets" {
  type = list(object({
    name = string
    rewrite_rules = list(object({
      name          = string
      rule_sequence = number
      conditions = list(object({
        variable    = string
        pattern     = string
        ignore_case = bool
        negate      = bool
      }))
      request_header_configurations = list(object({
        header_name  = string
        header_value = string
      }))
      response_header_configurations = list(object({
        header_name  = string
        header_value = string
      }))
      url = object({
        path         = string
        query_string = string
      })
    }))
  }))
  default = []
}

variable "backend_address_pools" {
  type = list(object({
    name         = string
    ip_addresses = optional(list(string))
    fqdns        = optional(list(string))
  }))
  default = []
}

variable "backend_http_settings" {
  type = list(object({
    name                           = string
    port                           = number
    protocol                       = string
    request_timeout                = number
    cookie_based_affinity          = bool
    affinity_cookie_name           = string
    host_name                      = string
    pick_host_name_from_backend    = bool
    path                           = string
    trusted_root_certificate_names = list(string)
    connection_draining_timeout    = number

    probe_settings = object({
      path                = string
      interval            = number
      timeout             = number
      unhealthy_threshold = number
      match = object({
        body        = string
        status_code = list(string)
      })
    })
  }))
  default = []
}

variable "http_listeners" {
  type = list(object({
    name                 = string
    host_name            = optional(string)
    host_names           = optional(list(string))
    ssl_certificate_name = optional(string)
    require_sni          = optional(bool)
  }))
  default = []
}

variable "backend_http_listeners" {
  type = list(object({
    name                       = string
    host_name                  = optional(string)
    host_names                 = optional(list(string))
    ssl_certificate_name       = optional(string)
    require_sni                = optional(bool)
    backend_address_pool_name  = string
    backend_http_settings_name = string
    rewrite_rule_set_name      = optional(string)
    priority                   = number
  }))
  default = []
}

variable "path_based_http_listeners" {
  type = list(object({
    name                               = string
    host_name                          = optional(string)
    host_names                         = optional(list(string))
    ssl_certificate_name               = optional(string)
    require_sni                        = optional(bool)
    priority                           = number
    default_backend_address_pool_name  = string
    default_backend_http_settings_name = string
    rewrite_rule_set_name              = optional(string)

    backend_configurations = list(object({
      name                       = string
      paths                      = list(string)
      backend_address_pool_name  = string
      backend_http_settings_name = string
      rewrite_rule_set_name      = optional(string)
    }))

    redirect_configurations = optional(list(object({
      name                        = string
      paths                       = list(string)
      redirect_configuration_name = string
    })))
  }))
  default = []
}

variable "redirect_http_listeners" {
  type = list(object({
    name                        = string
    host_name                   = optional(string)
    host_names                  = optional(list(string))
    ssl_certificate_name        = optional(string)
    require_sni                 = optional(bool)
    redirect_configuration_name = string
    priority                    = number
  }))
  default = []
}

variable "redirect_configurations" {
  type = list(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = bool
    include_query_string = bool
  }))
  default = []
}

variable "custom_monitor" {
  type        = bool
  description = "Enable custom monitor"
  default     = false
}

variable "resource_type" {
  type    = string
  default = "application_gateway"
}

variable "tags" {
  type = map(string)
}
