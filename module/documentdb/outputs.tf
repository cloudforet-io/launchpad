output "endpoint" {
  description = "Endpoint of the DocumentDB cluster"
  value       = module.documentdb_cluster.endpoint
}

output "database_user_name" {
  value       = var.master_username
}

output "database_user_password" {
  value       = var.master_password
}
