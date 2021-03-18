enabled = true
region = ""
vpc_id = ""
subnet_ids = ["",""]
allowed_security_groups = [""]

namespace = "spaceone"
stage = "test"
name = "docdb"


instance_class = "db.r5.large"
cluster_size = 2
db_port = 27017
cluster_parameters = [{"apply_method":"pending-reboot", "name":"tls", "value": "disabled"}]
master_username = "admin1"
master_password = "password1"

retention_period = 5
preferred_backup_window = "02:00-05:00"
cluster_family = "docdb3.6"
engine = "docdb"
storage_encrypted = false
skip_final_snapshot = true
apply_immediately = true
