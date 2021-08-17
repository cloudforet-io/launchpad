# Install Guide
This guide introduces how to quickly build an EKS cluster and spaceone.

The guide will install the resource set below.
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
The spaceone/launchpad repository contains scripts that create EKS and install spaceone.

### git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### set aws credential file
To access aws resource, you have to credential

```
vim launchpad/spaceone/package/conf/aws_credential
---
[spaceone_dev]
aws_access_key_id = [aws_access_key_id]
aws_secret_access_key = [aws_secret_access_key]
region = [default region]

```

### Setting up the configuration file

Setting up the configuration file.

the part that do not need to be installed, set enable to false.

ex) If you just need to install spaceone, set false of all infrastructure part and set true of all application part

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
Open browser(http://root.your-domain.com) and log in with the information below
- ID : user1@example.com
- PASSWORD : User123!@#

### SpaceONE Initial Stup
https://youtu.be/zSoEg2v_JrE

## Destroy
```
cd launchpad/spaceone/package/
```
```
. destroy.sh 
``` 

<hr>

Please contact us for any problems during the installation process.

https://discuss.spaceone.org/
