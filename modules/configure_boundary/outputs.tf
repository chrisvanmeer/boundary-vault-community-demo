output "boundary_target_alias" {
  value = var.boundary_target_alias
}

output "boundary_user_login" {
  value = var.guru_loginname
}

output "boundary_user_password" {
  value     = var.guru_password
  sensitive = true
}

output "boundary_auth_method_id" {
  value = boundary_auth_method.password.id
}

output "boundary_scope_id" {
  value = boundary_scope.org.id
}
