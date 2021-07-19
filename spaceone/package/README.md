# Install SpaceONE
This is a guide to installing SpaceONE on AWS EKS.

## Prerequisite
To install SpaceONE in this guide, the following is required.
- AWS credential settings
    - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
- terraform (>= 0.13.1)
    - https://learn.hashicorp.com/tutorials/terraform/install-cli
- Public domain Managed by Route53

To manage spaecone, the following is required.
- kubectl
    - https://v1-18.docs.kubernetes.io/docs/tasks/tools/install-kubectl/
- helm
    - https://helm.sh/docs/intro/install/


## Install

### 1. Clone the repo
```
git clone https://github.com/spaceone-dev/launchpad.git
```
### 2. Configure values
Edit Each auto.tfvars
- certificate
    - `launchpad/spaceone/package/certificate/certificate.auto.tfvars`
- eks
    - `launchpad/spaceone/package/eks/eks.auto.tfvars`
- deployment
    - `launchpad/spaceone/package/deployment/deployment.auto.tfvars`
- initialization
    - `launchpad/spaceone/package/initialization/domain.auto.tfvars`

### 3. Execute installation script
```
cd launchpad/spaceone/package/
sh install.sh build
```

## Destroy
To destroy SpaceONE and EKS clusters, you can use a script.
```
cd launchpad/spaceone/package/
sh install.sh destroy
``` 

## Upgrade
```
cd `launchpad/spaceone/package/deployment/yaml`
kubectl config set-context $(kubectl config current-context) --namespace spaceone
helm repo update

helm upgrade spaceone -f values.yaml -f frontend.yaml spaceone/spaceone
```

## Basic Stup
https://docs.spaceone.org/docs/guides/user_guide/gettingstart/setup/

## ect
### domain
- To access the console, access the address below
    - `root.console.<your root domain>`

### Management EKS cluster
- You can use kubectl to access your EKS Cluster.
    - When the installation is Complete, the config file of EKS Cluster is created in `$HOME/.kube/`
```
kubectl get pod
kubectl get nodes
...
```

