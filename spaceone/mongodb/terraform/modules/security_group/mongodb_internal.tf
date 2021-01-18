# SG for Internal networking in MongoDB Shard Cluster
resource "aws_security_group" "mongodb_internal_sg" {
  name        = "mongodb-internal-${var.environment}"
  vpc_id      = var.vpc_id

  # Outbound ALL
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "mongodb-internal-${var.environment}"
    Managed_by  = "terraform"
  }
}

resource "aws_security_group_rule" "mongodb_internal_ingress_rule_app_access" {
  type                          = "ingress"
  description                   = "Allow traffic for external access"
  source_security_group_id      = aws_security_group.mongodb_app_sg.id
  from_port                     = 27028
  to_port                       = 27028
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_internal_sg.id
  depends_on                    = [aws_security_group.mongodb_app_sg]
}

resource "aws_security_group_rule" "mongodb_internal_ingress_rule_bastion_access" {
  type                          = "ingress"
  description                   = "Allow traffic from mongo bastion"
  source_security_group_id      = aws_security_group.mongodb_bastion_sg.id
  from_port                     = 27028
  to_port                       = 27028
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_internal_sg.id
  depends_on                    = [aws_security_group.mongodb_bastion_sg]
}

resource "aws_security_group_rule" "mongodb_internal_ingress_rule_bastion_ssh_access" {
  type                          = "ingress"
  description                   = "Allow traffic from mongo bastion access"
  source_security_group_id      = aws_security_group.mongodb_bastion_sg.id
  from_port                     = 22
  to_port                       = 22
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_internal_sg.id
  depends_on                    = [aws_security_group.mongodb_bastion_sg]
}

resource "aws_security_group_rule" "mongodb_internal_ingress_rule_self_access" {
  type                          = "ingress"
  description                   = "Allow traffic for internal traffic"
  source_security_group_id      = aws_security_group.mongodb_internal_sg.id
  from_port                     = 27028
  to_port                       = 27028
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_internal_sg.id
  depends_on                    = [aws_security_group.mongodb_internal_sg]
}
