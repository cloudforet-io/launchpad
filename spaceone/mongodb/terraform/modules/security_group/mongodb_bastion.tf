# SG for MongoDB Bastion Access
resource "aws_security_group" "mongodb_bastion_sg" {
  name        = "mongodb-bastion-${var.environment}"
  vpc_id      = var.vpc_id

  # Outbound ALL
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "mongodb-bastion-${var.environment}"
    Managed_by  = "terraform"
  }
}

resource "aws_security_group_rule" "mongodb_bastion_ingress_rule_admin_access" {
  type                          = "ingress"
  description                   = "Allow access from CloudONE administrator"
  source_security_group_id      = var.mongodb_bastion_ingress_rule_admin_access_security_group_id
  from_port                     = var.mongodb_bastion_ingress_rule_admin_access_port
  to_port                       = var.mongodb_bastion_ingress_rule_admin_access_port
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_bastion_sg.id
}

