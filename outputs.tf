output "boundary_ip_address" {
  value = module.deploy.boundary_ip_address
}
output "boundary_user_login" {
  value = module.configure_boundary.boundary_user_login
}

output "boundary_user_password" {
  value     = module.configure_boundary.boundary_user_password
  sensitive = true
}

output "boundary_auth_method_id" {
  value = module.configure_boundary.boundary_auth_method_id
}
output "boundary_scope_id" {
  value = module.configure_boundary.boundary_scope_id
}
