output "mongodb_bastion_sg_id" {
  value = aws_security_group.mongodb_bastion_sg.id
}

output "mongodb_internal_sg_id" {
  value = aws_security_group.mongodb_internal_sg.id
}

output "mongodb_app_sg_id" {
  value = aws_security_group.mongodb_app_sg.id
}
