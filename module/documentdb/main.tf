module "documentdb_cluster" {
  source                          = "cloudposse/documentdb-cluster/aws"
  version                         = "0.13.0"
  cluster_size                    = var.cluster_size
  master_username                 = var.master_username
  master_password                 = var.master_password
  instance_class                  = var.instance_class
  db_port                         = var.db_port
  vpc_id                          = data.terraform_remote_state.eks.outputs.vpc_id
  subnet_ids                      = data.terraform_remote_state.eks.outputs.database_subnets
  apply_immediately               = var.apply_immediately
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  allowed_security_groups         = [data.terraform_remote_state.eks.outputs.cluster_security_group_id]
  allowed_cidr_blocks             = [data.terraform_remote_state.eks.outputs.vpc_cidr_block]
  snapshot_identifier             = var.snapshot_identifier
  retention_period                = var.retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  cluster_parameters              = var.cluster_parameters
  cluster_family                  = var.cluster_family
  engine                          = var.engine
  engine_version                  = var.engine_version
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  skip_final_snapshot             = var.skip_final_snapshot
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  cluster_dns_name                = var.cluster_dns_name
  reader_dns_name                 = var.reader_dns_name

  context = module.this.context
}

