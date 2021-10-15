#!/bin/bash

echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Start SpaceONE with minikube installation"

components=( "host" "kubelet" "apiserver" )
for component in "${components[@]}";
do
    minikube_status=$(minikube status | grep $component | cut -d':' -f2 | tr -d ' ')
    if [ $minikube_status != "Running" ]; then
        echo $component" of minikube is not in the running state"
        exit 1
    fi
done

mkdir ./minikube
cd ./minikube

kubectl create ns spaceone
kubectl create ns root-supervisor

kubectl config set-context $(kubectl config current-context) --namespace spaceone

helm repo add spaceone https://spaceone-dev.github.io/charts
helm repo list
helm repo update

git clone https://github.com/spaceone-dev/charts.git
cd charts/examples/v1.7.4

helm install spaceone -f minikube.yaml spaceone/spaceone --devel

echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Wait for the init-container to finish......"
while true
do
    status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
    if [ $status == "Completed" ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] SpaceONE with minikube has been installed successfully"
        kubectl port-forward -n spaceone svc/console 8080:80 &
        kubectl port-forward -n spaceone svc/console-api 8081:80 &
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] kubectl port-forward is running on background"
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Open your browser and access spaceone http://localhost:8080"
        break
    elif [ $status == "Failed" ] || [ "$status" == "Error" ] ; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Unable to process user domain creation.\n
                The state of the initialization container of the previous user domain is "$status
        exit 1
    fi
    sleep 1
done