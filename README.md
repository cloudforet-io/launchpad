# SpaceONE launchpad
This launchpad provides Spaceone in the standard configuration.

As a result, the following resources are created.
- Certificate managed by ACM
- VPC & EKS
- EKS controller for ingress and management dns records.
- DocumentDB
- IAM for Secret manager
- Kubernetes controllers
    - [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
    - [External DNS](https://github.com/kubernetes-sigs/external-dns)
- SpaceONE
    - root domain
    - user domain


![spaceone](https://user-images.githubusercontent.com/19552819/133223528-43291a11-8f47-4a51-9527-38c9f4297fee.png)

## Prerequisite
- docker ([document](https://docs.docker.com/engine/install/))
- public domain Managed by Route53

## Installation
Spaceone launchpad contains scripts to create an EKS cluster and install spaceone.

### git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### config aws credential file
You need aws credentials to access aws resources.

```
vim /conf/aws_credential
```
```
[default]
aws_access_key_id = [aws_access_key_id]
aws_secret_access_key = [aws_secret_access_key]
region = [default region]
```

### Setting up the configuration file

- `/conf/certificate.conf`    # for certificate
- `/conf/eks.conf`            # for eks
- `/conf/documentdb.conf`     # for document db
- `/conf/deployment.conf`     # for SpaceONE deployment
- `/conf/initialization.conf` # for initialize spaceone

### Execute script
It takes about 3~40 minutes to complete.
```
docker run --rm -v `pwd`:/spaceone spaceone/launchpad:0.1 -c install
```

The development type uses only Pod.
```
docker run --rm -v `pwd`:/spaceone spaceone/launchpad:0.1 -c install -t dev
```

### Login
After installation is completed, you can access spaceone console<br>
Open a browser(http://spaceone.console.your-domain.com) and log in to the root account with the information below.

- ID : admin
- PASSWORD : Admin123!@#(If you change domain_owner_password in initialization.conf, use it.)

### SpaceONE Basic Setup
For basic setup, please refer to the user guide or watch the YouTube video.

- SpaceONE User Guide
    - https://www.spaceone.org/docs/guides/user_guide/gettingstart/basic_setup/

- Youtube video
    - https://youtu.be/zSoEg2v_JrE 

## Management
### Upgrade SpaceONE
```
cd output/helm/spaceone
```
- Update value files
*)  Please refer to the [chart examples](https://github.com/spaceone-dev/charts) for update details.
```
vim {value|frontend|database}.yaml

or

vim minikube.yaml
```
- Upgrade helm chart
```
docker run --rm -v `pwd`:/spaceone spaceone/launchpad:0.1 -c upgrade
```

## destroy
```
docker run --rm -v `pwd`:/spaceone spaceone/launchpad:0.1 -c destroy
```

<hr>

SpaceONE discuss channel

https://discuss.spaceone.org/
