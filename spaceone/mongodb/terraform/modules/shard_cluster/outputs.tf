output "mongodb_config_servers" {
  value = aws_instance.mongodb_config.*
}

output "mongodb_rs_members" {
  value = aws_instance.mongodb_rs_member.*
}