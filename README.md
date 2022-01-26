# SpaceONE launchpad
The SpaceONE launchpad is a command line interface that allows you to easily install SpaceONE.

## Install in standard configuration
Basically, SpaceONE is a cloud native-based application.<br>
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

### Prerequisite
- Docker
- Public domain managed by Route53 (standard only)

### 1. git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### 2. set aws credential file
```
vim /vars/aws_credential.yaml
```
```
aws:
  aws_access_key_id : aws_access_key_id
  aws_secret_access_key : aws_secret_access_key
  region : default_region
```

### 3. Setting up the configuration file
- `/vars/certificate.conf`    # for certificate
- `/vars/eks.conf`            # for eks
- `/vars/documentdb.conf`     # for document db
- `/vars/deployment.conf`     # for SpaceONE helm chart
- `/vars/initialization.conf` # for initialize SpaceONE domain

### 4. Execute script
Execute launchpad script.(It takes about 3~40 minutes to complete.)<br>
```
./launchpad.sh install
```
## Install in minimal set
Also, SpaceONE can be installed as a minimum set.<br>
It only provides SpaceONE applications and alb ingress, other components are deployed as pods.

minimal set creates the following resources.
- VPC & EKS
- Kubernetes controllers
    - [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- SpaceONE
    - root domain
    - user domain

### Prerequisite
- Docker

### 1. git clone
```
git clone https://github.com/spaceone-dev/launchpad.git
```

### 2. set aws credential file
```
vim /vars/aws_credential.yaml
```
```
aws:
  aws_access_key_id : aws_access_key_id
  aws_secret_access_key : aws_secret_access_key
  region : default_region
```

### 3. Setting up the configuration file
- `/vars/eks.conf`            # for eks
- `/vars/deployment.conf`     # for SpaceONE helm chart
- `/vars/initialization.conf` # for initialize SpaceONE domain
### 4. Execute script
Execute launchpad script.(It takes about 3~40 minutes to complete.)<br>
```
./launchpad.sh install --minimal
```

## Install only SpaceONE application
If the kubernetes cluster already exists, only SpaceONE applications can be deployed.

---
**NOTE**

It does not provide ingress resources and uses [service of node port type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types).<br>
To expose SpaceONE to the outside
- [Install ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- Update SpaceONE values(refer to Management section of this document)<br>

---
### 1. set kubectl config 
```
cp /your/kubectl/config /data/kubeconfig/config
```
### 2. Setting up the configuration file
- `/vars/deployment.conf`     # for SpaceONE helm chart
- `/vars/initialization.conf` # for initialize SpaceONE domain

### 3. Execute script
```
./launchpad.sh deploy
```
## Login to SpaceONE
### standard
Open a browser(http://spaceone.console.your-domain.com) and log in to the root account with the information below.

- ID : `domain_owner` in initialization.conf
- PASSWORD : `domain_owner_password` in initialization.conf

### minimal
After the installation is complete, the domain record must be added to `/etc/hosts` on the local PC.<br>
Domain records will be displayed after installation is completed.

```diff
vim /etc/hosts
---
.
.
.
+xxx.xxx.xxx.xxx spaceone.console-dev.com
```

And Open a browser(http://spaceone.console-dev.com), log in to the root account with the information below.

- ID : `domain_owner` in initialization.conf
- PASSWORD : `domain_owner_password` in initialization.conf

### deploy
After the installation is complete, the access point will be displayed.

Open a browser(http://Node_IP:Port)log in to the root account with the information below.

- ID : `domain_owner` in initialization.conf
- PASSWORD : `domain_owner_password` in initialization.conf
## SpaceONE Basic Setup
For basic setup, please refer to the user guide or watch the YouTube video.

- [SpaceONE User Guide](https://www.spaceone.org/docs/guides/user_guide/gettingstart/basic_setup/)

- [Youtube video](https://youtu.be/zSoEg2v_JrE)

## Management
### Upgrade SpaceONE
To change SpaceONE configuration, Update helm value files and run upgrade command.

- Update value files
```
## standard version
vim data/helm/values/spaceone/{value|frontend|database}.yaml
```
```
## minimal version
vim data/helm/values/spaceone/minimal.yaml
```
- Upgrade helm chart
    - If there is a [new helm chart](https://github.com/spaceone-dev/charts), use the --update-repo option.
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
