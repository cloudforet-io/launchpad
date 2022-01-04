# SpaceONE launchpad
This launchpad provides Spaceone in the standard configuration.

As a result, the following resources are created.
- Certificate managed by ACM
- VPC & EKS
- DocumentDB
- IAM for Secret manager
- Kubernetes controllers
    - [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
    - [External DNS](https://github.com/kubernetes-sigs/external-dns)
- SpaceONE
    - root domain
    - user domain

![spaceone](https://user-images.githubusercontent.com/19552819/133223528-43291a11-8f47-4a51-9527-38c9f4297fee.png)

Also, SpaceONE can be installed in the minimal version.<br>
minimal version creates the following resources.
- VPC & EKS
- Kubernetes controllers
    - [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- SpaceONE
    - root domain
    - user domain

## Prerequisite
- Docker ([document](https://docs.docker.com/engine/install/))
- Public domain managed by Route53

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
- standard
    - `/vars/certificate.conf`    # for certificate
    - `/vars/eks.conf`            # for eks
    - `/vars/documentdb.conf`     # for document db
    - `/vars/deployment.conf`     # for SpaceONE helm chart
    - `/vars/initialization.conf` # for initialize SpaceONE domain
- minimal 
    - `/vars/eks.conf`            # for eks
    - `/vars/deployment.conf`     # for SpaceONE helm chart
    - `/vars/initialization.conf` # for initialize SpaceONE domain

### Execute script
Execute launchpad script.(It takes about 3~40 minutes to complete.)<br>
If you want the minimal version, add the `--minimal` option.<br>
```
./launchpad.sh install [--minimal]
```

## Login to SpaceONE
### standard
After installation is completed, you can access SpaceONE console<br>
Open a browser(http://spaceone.console.your-domain.com) and log in to the root account with the information below.

- ID : `domain_owner` in initialization.com
- PASSWORD : `domain_owner_password` in initialization.com

### minimal
After the installation is complete, the domain record must be added to /etc/hosts on the local PC.<br>
Domain records will be displayed after installation is completed.

```diff
vim /etc/hosts
---
.
.
.
+xxx.xxx.xxx.xxx spaceone.console-dev.com
```

And, Open a browser(http://spaceone.console-dev.com) and log in to the root account with the information below.

- ID : `domain_owner` in initialization.com
- PASSWORD : `domain_owner_password` in initialization.com

### SpaceONE Basic Setup
For basic setup, please refer to the user guide or watch the YouTube video.

- [SpaceONE User Guide](https://www.spaceone.org/docs/guides/user_guide/gettingstart/basic_setup/)

- [Youtube video](https://youtu.be/zSoEg2v_JrE)

## Management
### Upgrade SpaceONE
To change SpaceONE configuration, modify the helm value and run upgrade.

- Update value files
```
## standard version
vim data/helm/values/spaceone/{value|frontend|database}.yaml

## minimal version
vim data/helm/values/spaceone/minimal.yaml
```
- Upgrade helm chart
    - If you are upgrading to a new release, use the --update-repo option.
```
./launchpad.sh upgrade {--update-repo}
```

### Destroy SpaceONE
```
./launchpad.sh destroy
```

<hr>

SpaceONE discuss channel<br>
https://discuss.spaceone.org/

SpaceONE release example<br>
https://github.com/spaceone-dev/charts