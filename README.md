# launchpad

SpaceONE infrastructure automation provisioning code

* Based on AWS
* Implementation of Terraform and Ansible

<hr/>


## Architecture
 
![MongoDB](./mongodb_arch_img.jpg)


## Terraform

* Guaranteed Terraform Version 0.14.2
* Separated workspace from each supported parts
* Thus, Each parts is must be executed separately

### Supported Part list
* mongodb

### Modules
* bastion
* route53
* security_group
* shard_cluster

<br/>

### How to use

#### 1. Terraform init

we recommended to use S3 Backend for state management and state locking.

`backend.tfvars` file looks like

<pre>
<code>
# AWS S3 bucket name for backend
bucket = ""

# AWS S3 object key for tfstate file
key = ""

region = ""

# support locking via DynamoDB
dynamodb_table = ""

</code></pre>

Fill out `backend.tfvars` values and `terraform init` run

<pre>
<code>> terraform init --var-file=backend.tfvars</code>
</pre>

<br/>

#### 2. Fill out `*.auto.tfvars` for environments

Each parts included `.auto.tfvars` files for your environment properly.

For example, mongodb parts included `security_group.auto.tfvars` and `shard_cluster.auto.tfvars`.

Let's see a `security_group.auto.tfvars` for instance.
<pre> # security_group.tfvars
<code>
region                        =   ""
vpc_id                        =   ""

mongodb_bastion_ingress_rule_admin_access_security_group_id = ""    # From Source security group ID for Administrator access
mongodb_bastion_ingress_rule_admin_access_port              = 0
mongodb_app_ingress_rule_mongodb_access_security_group_id   = ""    # From Source security group ID for Worker Nodes
</code>
</pre>

You can fill out all of `.auto.tfvars` in each parts.

#### 2-1. Fill out SSH PEM String to access ec2 instances through SSH for Ansible if you want

Configure for Ansible in bastion instance automatically.
Fill out SSH PEM Key string to access each nodes through bastion Ansible if you want.
PEM Key string must be the same when deploy instances selected key pairs.

`spaceone/terraform/modules/ssh_pem/mongodb.pem`

<pre> # mongodb.pem
<code>
-----BEGIN RSA PRIVATE KEY-----
ENTER_YOUR_PRIVATE_KEY_STRING
-----END RSA PRIVATE KEY-----
</code>
</pre>


if you don't set SSH Key, you must set PEM key in bastion manually for Ansible after deployment.

#### 3. Terraform plan

And then, make file for your environment.

We already add `default.auto.tfvars` for example.

`default.auto.tfvars` is simple. It looks like

<pre>
<code>environment   = "dev"
region        = ""</code>
</pre>

Fill out the values in `default.auto.tfvars`.

It's time to run the `Terraform plan` !

If you run the mongodb with all of `tfvars` in mongodb parts,  
<pre>
<code>> terraform plan </code>
</pre>


#### 4. Terraform apply

Go to build your spaceONE using launchpad !
<pre>
<code>> terraform apply </code>
</pre>

<br>
<hr/>


## Ansible


### Roles
* ubuntu_base
* mongodb_base
* mongod
* mongos
* config_replicaset
* data_node_replicaset
* shard_cluster
* bastion

### How to use

#### 1. Access Bastion Instance

#### 2. Access Test for 

We will use Ansible dynamic inventory. 
Configure for using Ansible dynamic inventory automatically. You don't need to anything to configure for it.
Please check do `ansible-inventory` command.

<pre>
<code>> ansible-inventory --graph </code>
</pre>

#### 3. Fill out Variables in mongodb playbook

`spaceone/ansible/roles/mongodb.yml`

We will run ansible playbook `mongodb.yml` only. This playbook is included variety roles for configuration MongoDB.
You must set variables in this playbook for use.

#### 4. Run playbook!

Ready to Run. 
It's simple! Run playbook now.

<pre>
<code>> ansible-playbook mongodb.yml </code>
</pre>