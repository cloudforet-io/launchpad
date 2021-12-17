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
Spaceone launchpad contains scripts to create all Components of SpaceONE.

### git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### config aws credential file
You need aws credentials to access aws resources.

```
vim /vars/aws_credential
```
```
[default]
aws_access_key_id = [aws_access_key_id]
aws_secret_access_key = [aws_secret_access_key]
region = [default region]
```

### Setting up the configuration file

- `/vars/certificate.conf`    # for certificate
- `/vars/eks.conf`            # for eks
- `/vars/documentdb.conf`     # for document db
- `/vars/deployment.conf`     # for SpaceONE helm chart
- `/vars/initialization.conf` # for initialize SpaceONE domain

### Execute script
It takes about 3~40 minutes to complete.
```
./launchpad.sh install
```

## Login to SpaceONE
After installation is completed, you can access SpaceONE console<br>
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

- Update value files
    - see a for details, refer to [chart examples](https://github.com/spaceone-dev/charts)
```
## enterprise version
vim data/helm/values/spaceone/{value|frontend|database}.yaml
```
- Upgrade helm chart
```
./launchpad.sh upgrade
```

### Destroy SpaceONE
```
./launchpad.sh destroy
```

<hr>

SpaceONE discuss channel

https://discuss.spaceone.org/
