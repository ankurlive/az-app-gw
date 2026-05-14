variable "resource_group_name" {}
variable "location" {}
variable "appgw" {
  type = object({
    subnet_id    = string
    private_ip   = string
    sku_capacity = number
  })
}
variable "is_public" {
  type = bool
}
variable "environment" {
  type = string
}
variable "instance_number" {
  type = string
}
variable "sku" {
  type = string
}
variable "enable_http2" {
  type = bool
}
variable "enable_autoscale" {
  type = bool
}
variable "autoscale_min_capacity" {
  type = number
}
variable "autoscale_max_capacity" {
  type = number
}
variable "tenant_id" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type      = string
  sensitive = true
}
variable "trusted_root_certificate" {
  type = list(object({
    name = string
    data = string
  }))
}
variable "ssl_certificates" {
  type = list(object({
    name                = string
    key_vault_secret_id = string
  }))
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
}
variable "backend_address_pools" {
  type = list(object({
    name         = string
    ip_addresses = optional(list(string))
    fqdns        = optional(list(string))
  }))
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
}
variable "http_listeners" {
  type = list(object({
    name                 = string
    host_name            = optional(string)
    host_names           = optional(list(string))
    ssl_certificate_name = optional(string)
    require_sni          = optional(bool)
  }))
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
}
variable "custom_monitor" {
  type = bool
}
variable "resource_type" {
  type = string
}
variable "tags" {
  type = map(string)
}
