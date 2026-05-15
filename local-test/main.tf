locals {
  # ----------------------------------------
  # Azure Provider Credentials (Option 2)
  # ----------------------------------------
  tenant_id       = "xxxxxxxxxx"
  subscription_id = "xxxxxxxxxxx"
  client_id       = "xxxxxxxxx"
  client_secret   = "xxxxxxxxx"

  # ----------------------------------------
  # Core Module Inputs
  # ----------------------------------------
  resource_group_name    = "rg-appgw-demo"
  location               = "eastus"
  environment            = "dev"
  instance_number        = "01"
  sku                    = "WAF_v2"
  enable_http2           = false
  enable_autoscale       = false
  autoscale_min_capacity = 0
  autoscale_max_capacity = 10
  is_public              = true
  custom_monitor         = false
  resource_type          = "application_gateway"

  # ----------------------------------------
  # Tags
  # ----------------------------------------
  tags = {
    environment = "dev"
    owner       = "platform"
  }

  # ----------------------------------------
  # Application Gateway Base Object
  # ----------------------------------------
  appgw = {
    subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-demo/providers/Microsoft.Network/virtualNetworks/vnet-demo/subnets/snet-appgw"
    private_ip   = "10.0.2.10"
    sku_capacity = 2
  }

  # ----------------------------------------
  # ✅ UPDATED: Backend Pools (FQDN instead of IP)
  # ----------------------------------------
  backend_address_pools = [
    {
      name  = "pool-app1"
      fqdns = ["LOUSQLWTS4527.humad.com"]
    }
  ]

  # ----------------------------------------
  # ✅ UPDATED: Backend HTTP Settings (hostname updated)
  # ----------------------------------------
  backend_http_settings = [
    {
      name                           = "bhs-app1-https"
      port                           = 443
      protocol                       = "Https"
      request_timeout                = 30
      cookie_based_affinity          = false
      affinity_cookie_name           = ""
      host_name                      = "LOUSQLWTS4527.humad.com"   # ✅ changed
      pick_host_name_from_backend    = false
      path                           = "/"
      trusted_root_certificate_names = []
      connection_draining_timeout    = 0
      probe_settings = {
        path                = "/health"
        interval            = 30
        timeout             = 30
        unhealthy_threshold = 3
        match = {
          body        = ""
          status_code = ["200-399"]
        }
      }
    }
  ]

  # ----------------------------------------
  # Listener Configurations
  # ----------------------------------------
  http_listeners = []

  backend_http_listeners = [
    {
      name                       = "listener-app1"
      host_name                  = "app1.contoso.com"   # ✅ unchanged (correct)
      host_names                 = null
      ssl_certificate_name       = "cert-app1"
      require_sni                = false
      backend_address_pool_name  = "pool-app1"
      backend_http_settings_name = "bhs-app1-https"
      rewrite_rule_set_name      = null
      priority                   = 100
    }
  ]

  path_based_http_listeners = []
  redirect_http_listeners   = []
  redirect_configurations   = []

  # ----------------------------------------
  # Certificates and Rewrite Rules
  # ----------------------------------------
  trusted_root_certificate = []
  ssl_certificates = [
    {
      name                = "cert-app1"
      key_vault_secret_id = "https://kv-demo.vault.azure.net/secrets/appgw-cert/00000000000000000000000000000000"
    }
  ]
  rewrite_rule_sets = []
}

module "appgw" {
  source = "../modules/application-gateway"

  resource_group_name       = local.resource_group_name
  location                  = local.location
  appgw                     = local.appgw
  is_public                 = local.is_public
  environment               = local.environment
  instance_number           = local.instance_number
  sku                       = local.sku
  enable_http2              = local.enable_http2
  enable_autoscale          = local.enable_autoscale
  autoscale_min_capacity    = local.autoscale_min_capacity
  autoscale_max_capacity    = local.autoscale_max_capacity
  trusted_root_certificate  = local.trusted_root_certificate
  ssl_certificates          = local.ssl_certificates
  rewrite_rule_sets         = local.rewrite_rule_sets
  backend_address_pools     = local.backend_address_pools
  backend_http_settings     = local.backend_http_settings
  http_listeners            = local.http_listeners
  backend_http_listeners    = local.backend_http_listeners
  path_based_http_listeners = local.path_based_http_listeners
  redirect_http_listeners   = local.redirect_http_listeners
  redirect_configurations   = local.redirect_configurations
  custom_monitor            = local.custom_monitor
  resource_type             = local.resource_type
  tags                      = local.tags
}
