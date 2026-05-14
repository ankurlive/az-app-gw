module "appgw" {
  source = "../modules/application-gateway"

  resource_group_name       = var.resource_group_name
  location                  = var.location
  appgw                     = var.appgw
  is_public                 = var.is_public
  environment               = var.environment
  instance_number           = var.instance_number
  sku                       = var.sku
  enable_http2              = var.enable_http2
  enable_autoscale          = var.enable_autoscale
  autoscale_min_capacity    = var.autoscale_min_capacity
  autoscale_max_capacity    = var.autoscale_max_capacity
  trusted_root_certificate  = var.trusted_root_certificate
  ssl_certificates          = var.ssl_certificates
  rewrite_rule_sets         = var.rewrite_rule_sets
  backend_address_pools     = var.backend_address_pools
  backend_http_settings     = var.backend_http_settings
  http_listeners            = var.http_listeners
  backend_http_listeners    = var.backend_http_listeners
  path_based_http_listeners = var.path_based_http_listeners
  redirect_http_listeners   = var.redirect_http_listeners
  redirect_configurations   = var.redirect_configurations
  custom_monitor            = var.custom_monitor
  resource_type             = var.resource_type
  tags                      = var.tags
}
