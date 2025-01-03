output "boundary_ip_address" {
  value = module.deploy.boundary_ip_address
}

output "client_pub_ip" {
  value = module.deploy.boundary_client_public_ip_address
}
