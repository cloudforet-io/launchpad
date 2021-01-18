# launchpad

SpaceONE infrastructure automation provisioning code

* Based on AWS
* Implementation of Terraform and Ansible

<hr/>

## Terraform

* Guaranteed Terraform Version 0.14.2
* Separated workspace from each supported parts
* Thus, Each parts is must be executed separately

### Supported Part list
* mongodb



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


