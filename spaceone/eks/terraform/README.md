# Introduction

This terraform creates

1) VPC
2) EKS

https://github.com/terraform-aws-modules/terraform-aws-eks

# Install

## Configure environments

Prepare your AWS credentials. Put your ~/.aws/credentials

edit eks.auto.tfvars

This is your environment variables.

***region*** is aws region name for installation.

~~~
region = "us-east-1"
~~~

## Execute terraform

If you don't have terraform binary, see [Reference](#Reference)
~~~
terraform init
terraform plan
terraform apply
~~~

## Configure kubernetes

After installation, ***kubeconfig_spaceone-prd-eks*** file will be created. This file is config of kubernetes.

If you don't have kubectl, see [Reference](#Reference)
You may also install aws-iam-authenticator, see [Reference](#Reference)
~~~
cp kubecconfig_spaceone-prd-eks ~/.kube/config
~~~


# Reference

[How to install terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
[How to install kubectl](https://kubernetes.io/docs/tasks/tools/)
[How to install aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)


