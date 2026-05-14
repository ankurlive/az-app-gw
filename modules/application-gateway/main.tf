locals {
  appgw_name               = "az3-${var.location}-${var.environment}-${var.instance_number}-ag"
  frontend_internal_name   = "frontend-private"
  frontend_external_name   = "frontend-public"
  frontend_port_https      = "https"
  frontend_port_http       = "http"
  autoscale_config         = { min = var.autoscale_min_capacity, max = var.autoscale_max_capacity }
  all_https_listeners      = concat(var.http_listeners, var.backend_http_listeners, var.path_based_http_listeners, var.redirect_http_listeners)
  basic_route_listeners    = var.backend_http_listeners
  path_route_listeners     = var.path_based_http_listeners
  redirect_route_listeners = var.redirect_http_listeners
  frontend_ports = [
    { name = local.frontend_port_https, port = 443 },
    { name = local.frontend_port_http, port = 80 }
  ]
  private_frontend_ip = {
    name                          = local.frontend_internal_name
    subnet_id                     = var.appgw.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.appgw.private_ip
  }
  public_frontend_ips = var.is_public ? [{
    name                 = local.frontend_external_name
    public_ip_address_id = azurerm_public_ip.appgw[0].id
  }] : []
  all_frontends = concat([local.private_frontend_ip], local.public_frontend_ips)
  path_maps = [
    for listener in var.path_based_http_listeners : {
      name                                = listener.name
      default_backend_address_pool_name   = listener.default_backend_address_pool_name
      default_backend_http_settings_name  = listener.default_backend_http_settings_name
      default_redirect_configuration_name = null
      path_rules = concat(
        [
          for backend_cfg in listener.backend_configurations : {
            name                        = backend_cfg.name
            paths                       = backend_cfg.paths
            backend_address_pool_name   = backend_cfg.backend_address_pool_name
            backend_http_settings_name  = backend_cfg.backend_http_settings_name
            redirect_configuration_name = null
            rewrite_rule_set_name       = try(backend_cfg.rewrite_rule_set_name, null)
          }
        ],
        [
          for redirect_cfg in try(listener.redirect_configurations, []) : {
            name                        = redirect_cfg.name
            paths                       = redirect_cfg.paths
            backend_address_pool_name   = null
            backend_http_settings_name  = null
            redirect_configuration_name = redirect_cfg.redirect_configuration_name
            rewrite_rule_set_name       = null
          }
        ]
      )
    }
  ]
}

resource "azurerm_public_ip" "appgw" {
  count               = var.is_public ? 1 : 0
  name                = "${local.appgw_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = local.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_http2        = var.enable_http2

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.enable_autoscale ? null : var.appgw.sku_capacity
  }

  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscale ? [local.autoscale_config] : []
    content {
      min_capacity = autoscale_configuration.value.min
      max_capacity = autoscale_configuration.value.max
    }
  }

  gateway_ip_configuration {
    name      = "${local.appgw_name}-ip-configuration"
    subnet_id = var.appgw.subnet_id
  }

  dynamic "frontend_ip_configuration" {
    for_each = local.all_frontends
    content {
      name                          = frontend_ip_configuration.value.name
      subnet_id                     = try(frontend_ip_configuration.value.subnet_id, null)
      private_ip_address_allocation = try(frontend_ip_configuration.value.private_ip_address_allocation, null)
      private_ip_address            = try(frontend_ip_configuration.value.private_ip_address, null)
      public_ip_address_id          = try(frontend_ip_configuration.value.public_ip_address_id, null)
    }
  }

  dynamic "frontend_port" {
    for_each = local.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      ip_addresses = try(backend_address_pool.value.ip_addresses, null)
      fqdns        = try(backend_address_pool.value.fqdns, null)
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity ? "Enabled" : "Disabled"
      affinity_cookie_name                = backend_http_settings.value.cookie_based_affinity ? backend_http_settings.value.affinity_cookie_name : null
      host_name                           = backend_http_settings.value.pick_host_name_from_backend ? null : backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend
      path                                = backend_http_settings.value.path
      probe_name                          = backend_http_settings.value.probe_settings != null ? backend_http_settings.value.name : null
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining_timeout > 0 ? [1] : []
        content {
          enabled           = true
          drain_timeout_sec = backend_http_settings.value.connection_draining_timeout
        }
      }
    }
  }

  dynamic "probe" {
    for_each = [for p in var.backend_http_settings : p if p.probe_settings != null]
    content {
      name                                      = probe.value.name
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend
      host                                      = probe.value.pick_host_name_from_backend ? null : probe.value.host_name
      port                                      = probe.value.port
      protocol                                  = probe.value.protocol
      path                                      = probe.value.probe_settings.path
      interval                                  = probe.value.probe_settings.interval
      timeout                                   = probe.value.probe_settings.timeout
      unhealthy_threshold                       = probe.value.probe_settings.unhealthy_threshold

      match {
        body        = probe.value.probe_settings.match.body
        status_code = probe.value.probe_settings.match.status_code
      }
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificate
    content {
      name = trusted_root_certificate.value.name
      data = trusted_root_certificate.value.data
    }
  }

  dynamic "http_listener" {
    for_each = local.all_https_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = var.is_public ? local.frontend_external_name : local.frontend_internal_name
      frontend_port_name             = local.frontend_port_https
      protocol                       = "Https"
      host_name                      = try(http_listener.value.host_name, null)
      host_names                     = try(http_listener.value.host_names, null)
      ssl_certificate_name           = try(http_listener.value.ssl_certificate_name, null)
      require_sni                    = try(http_listener.value.require_sni, false)
    }
  }

  dynamic "http_listener" {
    for_each = local.all_https_listeners
    content {
      name                           = "http2https_${http_listener.value.name}"
      frontend_ip_configuration_name = var.is_public ? local.frontend_external_name : local.frontend_internal_name
      frontend_port_name             = local.frontend_port_http
      protocol                       = "Http"
      host_name                      = try(http_listener.value.host_name, null)
      host_names                     = try(http_listener.value.host_names, null)
    }
  }

  dynamic "redirect_configuration" {
    for_each = local.all_https_listeners
    content {
      name                 = "http2https_${redirect_configuration.value.name}"
      redirect_type        = "Permanent"
      target_listener_name = redirect_configuration.value.name
      include_path         = true
      include_query_string = true
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = try(redirect_configuration.value.target_listener_name, null)
      target_url           = try(redirect_configuration.value.target_url, null)
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.all_https_listeners
    content {
      name                        = "http2https_${request_routing_rule.value.name}"
      rule_type                   = "Basic"
      http_listener_name          = "http2https_${request_routing_rule.value.name}"
      redirect_configuration_name = "http2https_${request_routing_rule.value.name}"
      priority                    = try(request_routing_rule.value.priority, 100) + 1
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.basic_route_listeners
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.value.name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      rewrite_rule_set_name      = try(request_routing_rule.value.rewrite_rule_set_name, null)
      priority                   = request_routing_rule.value.priority
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.path_route_listeners
    content {
      name               = request_routing_rule.value.name
      rule_type          = "PathBasedRouting"
      http_listener_name = request_routing_rule.value.name
      url_path_map_name  = "url-path-map-${request_routing_rule.value.name}"
      priority           = request_routing_rule.value.priority
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.redirect_route_listeners
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.value.name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      priority                    = request_routing_rule.value.priority
    }
  }

  dynamic "url_path_map" {
    for_each = local.path_maps
    content {
      name                                = "url-path-map-${url_path_map.value.name}"
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                        = "path-rule-${path_rule.value.name}"
          paths                       = path_rule.value.paths
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
        }
      }
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.conditions
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configurations
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configurations
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = rewrite_rule.value.url != null ? [rewrite_rule.value.url] : []
            content {
              path         = url.value.path
              query_string = url.value.query_string
            }
          }
        }
      }
    }
  }

  tags = var.tags
}
