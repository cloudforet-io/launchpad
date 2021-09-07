# Onestop Install Guide
This guide introduces to onestop create EKS cluster and install spaceone.

As a result, the following resources are created.
- Certificate managed by ACM
- VPC & EKS
- Kubernetes controllers
    - [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
    - [External DNS](https://github.com/kubernetes-sigs/external-dns)
- SpaceONE

## Prerequisite
- terraform (>= 0.13.1)
    - https://learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform
- kubectl
    - on linux
        - https://v1-18.docs.kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-with-curl-on-linux
    - on mac
        - https://v1-18.docs.kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-with-curl-on-macos
- helm
    - https://helm.sh/docs/intro/install/#from-script
- Public domain Managed by Route53

## Installation
The spaceone/launchpad repository contains scripts that create EKS cluster and install spaceone.

### git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### set aws credential file

You need aws credentials to access aws resources and create EKS.

```
vim launchpad/spaceone/package/conf/aws_credential
```
```
[spaceone_dev]
aws_access_key_id = [aws_access_key_id]
aws_secret_access_key = [aws_secret_access_key]
region = [default region]
```

### Setting up the configuration file

Configuration file settings for infrastructure resources and spaceone

The part that do not need to be created, set enable to false.

:information_source: If you just need to install spaceone, set false of all infrastructure part and set true of all application part


- infrastructure part
    1. certificate
        - `launchpad/spaceone/package/infrastructure/conf/certificate.conf`
    2. eks
        - `launchpad/spaceone/package/infrastructure/conf/eks.conf`
    3. controllers
        - `launchpad/spaceone/package/application/conf/controllers.conf`
- application part
    1. deployment
        - `launchpad/spaceone/package/application/conf/deployment.conf`
    2. initialization
        - `launchpad/spaceone/package/application/conf/initialization.conf`

### Start the install
It takes about 2~30 minutes to complete.
```
cd launchpad/spaceone/package/
```
```
chmod +x install.sh
```
```
./install.sh
```

### Login
After installation is complete, you can access spaceone console<br>
Open browser(http://root.your-domain.com or http://domain-1.you-domain.comn) and-log in with the information below

- admin
    - ID : admin
    - PASSWORD : Admin123!@#
- user
    - ID : user1@example.com
    - PASSWORD : User123!@#

### SpaceONE Initial Stup
https://youtu.be/zSoEg2v_JrE

## Destroy
```
cd launchpad/spaceone/package/
```
```
chmod +x install.sh
```
```
./destroy.sh 
``` 

<hr>

Please contact us for any problems during the installation process.

https://discuss.spaceone.org/
