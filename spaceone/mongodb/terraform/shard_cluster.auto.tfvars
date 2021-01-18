/*
    Variables for MongoDB Shard Cluster
*/

// MongoDB Bastion
mongodb_ami_id                  = ""     # Ubuntu 18.04 LTS
mongodb_bastion_instance_type   = "t3.micro"
mongodb_bastion_subnet_id       = ""
mongodb_bastion_keypair_name    = ""       # Prepared to be existed

// MongoDB Config Servers
mongodb_keypair_name            = ""       # Prepared to be existed
mongodb_config_instance_type    = "c5.large"
mongodb_config_server           = [
  {
    name          =   "mongodb-cfg1",
    subnet_id     =   ""
    rs_primary    =   true

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  },
  {
    name          =   "mongodb-cfg2",
    subnet_id     =   ""
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  },
  {
    name          =   "mongodb-cfg3",
    subnet_id     =   ""
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  }
]

// MongoDB Replica Set Members
mongodb_replica_set_members = [
  {
    name          =   "mongodb-s1d1",                     # Replica Set 1
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "1"
    rs_type       =   "data"
    rs_primary    =   true

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s1d2",
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "1"
    rs_type       =   "data"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s1d3",                     # Replica Set 1 (Arbiter)
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "1"
    rs_type       =   "arbiter"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  },
  {
    name          =   "mongodb-s2d1",                     # Replica Set 2
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "2"
    rs_type       =   "data"
    rs_primary    =   true

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s2d2",
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "2"
    rs_type       =   "data"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s2d3",                     # Replica Set 2 (Arbiter)
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "2"
    rs_type       =   "arbiter"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  },
  {
    name          =   "mongodb-s3d1",                     # Replica Set 3
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "3"
    rs_type       =   "data"
    rs_primary    =   true

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s3d2",
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "3"
    rs_type       =   "data"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices   =   [
      {
        device_name =   "/dev/sdb"
        volume_type =   "gp3",
        volume_size =   2000
      }
    ]
  },
  {
    name          =   "mongodb-s3d3",                     # Replica Set 3 (Arbiter)
    instance_type =   "c5.2xlarge",
    subnet_id     =   ""
    replica_set   =   "3"
    rs_type       =   "arbiter"
    rs_primary    =   false

    root_device   =   {
      volume_type =   "gp3",
      volume_size =   100
    },
    data_devices  =   []
  }
]
