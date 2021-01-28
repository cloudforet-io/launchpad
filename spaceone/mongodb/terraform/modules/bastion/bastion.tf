resource "aws_iam_role" "ec2_read_only_role" {
  name                =   "${var.environment}-EC2-read-only"
  assume_role_policy  =   file("${path.module}/policy/ec2_assume_policy.json")

  tags = {
    Managed_by        =   "terraform"
  }
}

resource "aws_iam_role_policy" "ec2_read_only_policy" {
  name                =   "${var.environment}-EC2-readonly-policy"
  role                =   aws_iam_role.ec2_read_only_role.id
  policy              =   file("${path.module}/policy/ec2_read_only_policy.json")
}

resource "aws_iam_instance_profile" "ec2_read_only_profile" {
  name                =   "${var.environment}-EC2-readonly-profile"
  role                =   aws_iam_role.ec2_read_only_role.name
}

data "template_file" "ansible_init" {
  template                =   file("${path.module}/template/ansible_install.sh.tpl")

  vars = {
    region                =   var.region
    mongodb_ssh_pem       =   file("${path.module}/ssh_pem/mongodb.pem")
  }
}

resource "aws_eip" "bastion_eip" {
  vpc             =   true

  tags = {
    Name          =   "mongodb-bastion-${var.environment}-eip"
    Managed_by    =   "terraform"
  }
}

resource "aws_instance" "mongodb_bastion" {
  ami                           =   var.mongodb_ami_id
  subnet_id                     =   var.mongodb_bastion_subnet_id
  instance_type                 =   var.mongodb_bastion_instance_type
  key_name                      =   var.mongodb_bastion_keypair_name
  vpc_security_group_ids        =   var.mongodb_bastion_security_group_ids

  tags = {
    Name          =   "mongodb-bastion-${var.environment}"
    server_type   =   "mongodb-bastion"
    Managed_by    =   "terraform"
    rs_type       =   "mongos"
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id     =   aws_instance.mongodb_bastion.id
  allocation_id   =   aws_eip.bastion_eip.id
}
