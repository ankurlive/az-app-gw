output "application_gateway_id" {
  value = azurerm_application_gateway.appgw.id
}

output "frontend_private_ip" {
  value = var.appgw.private_ip
}

output "frontend_public_ip" {
  value = var.is_public && length(azurerm_public_ip.appgw) > 0 ? azurerm_public_ip.appgw[0].ip_address : null
}
