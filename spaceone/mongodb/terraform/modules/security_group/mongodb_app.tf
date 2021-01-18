
# SG for Application networking to MongoDB Shard Cluster
resource "aws_security_group" "mongodb_app_sg" {
  name        = "mongodb-app-${var.environment}"
  vpc_id      = var.vpc_id

  # Outbound ALL
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "mongodb-app-${var.environment}"
    Managed_by  = "terraform"
  }
}

resource "aws_security_group_rule" "mongodb_app_ingress_rule_bastion_access" {
  type                          = "ingress"
  description                   = "Allow traffic from mongo bastion access"
  source_security_group_id      = aws_security_group.mongodb_bastion_sg.id
  from_port                     = 22
  to_port                       = 22
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_app_sg.id
  depends_on                    = [aws_security_group.mongodb_bastion_sg]
}

resource "aws_security_group_rule" "mongodb_app_ingress_rule_mongodb_access" {
  type                          = "ingress"
  description                   = "Allow traffic for mongos server"
  source_security_group_id      = var.mongodb_app_ingress_rule_mongodb_access_security_group_id
  from_port                     = 27028
  to_port                       = 27028
  protocol                      = "tcp"
  security_group_id             = aws_security_group.mongodb_app_sg.id
  depends_on                    = [aws_security_group.mongodb_bastion_sg]
}
