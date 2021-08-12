#!/bin/sh

function is_enable() {
    local component=$1
    local base_working_dir=$base_working_dir

    is_enable=$(cat $base_working_dir/conf/$component.conf | grep 'enable' | cut -d'=' -f2 | cut -d'"' -f2)
    if [ $is_enable != true ]; then
        echo 1
    elif [ $is_enable = true ]; then
        echo 0
    fi
}

function configure() {
    local component=$1
    local base_working_dir=$2

    case $component in
        controllers) 
                    domain_name=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.domain_name.value')
                    cluster_oidc_issuer_url=$(cat $base_working_dir/outputs/terraform_states/eks.tfstate | jq '.outputs.cluster_oidc_issuer_url.value' | sed 's/\//\\\//g')

                    sed 's/domain_name             = ""/domain_name             = '$domain_name'/g' $base_working_dir/conf/$component.conf > $base_working_dir/conf/tmp.$component.auto.tfvars
                    sed 's/cluster_oidc_issuer_url = ""/cluster_oidc_issuer_url = '$cluster_oidc_issuer_url'/g' $base_working_dir/conf/tmp.$component.auto.tfvars > $base_working_dir/conf/$component.auto.tfvars
                    ;;
        deployment)
                    console_api_domain=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_api_domain.value')
                    console_api_certificate_arn=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_api_certificate_arn.value' | sed 's/\//\\\//g')
                    console_domain=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_domain.value')
                    console_certificate_arn=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_certificate_arn.value' | sed 's/\//\\\//g')

                    sed 's/console_api_domain          = ""/console_api_domain          = '$console_api_domain'/g' $base_working_dir/conf/$component.conf > $base_working_dir/conf/tmp.$component.auto.tfvars
                    sed 's/console_api_certificate_arn = ""/console_api_certificate_arn = '$console_api_certificate_arn'/g' $base_working_dir/conf/tmp.$component.auto.tfvars > $base_working_dir/conf/tmp1.$component.auto.tfvars
                    sed 's/console_domain              = ""/console_domain              = '$console_domain'/g' $base_working_dir/conf/tmp1.$component.auto.tfvars > $base_working_dir/conf/tmp2.$component.auto.tfvars
                    sed 's/console_certificate_arn     = ""/console_certificate_arn     = '$console_certificate_arn'/g' $base_working_dir/conf/tmp2.$component.auto.tfvars > $base_working_dir/conf/$component.auto.tfvars
                    ;;
        *)
                    cp $base_working_dir/conf/$component.conf $base_working_dir/conf/$component.auto.tfvars
                    ;;
    esac

    sed '1d' $base_working_dir/conf/$component.auto.tfvars > $base_working_dir/src/$component/$component.auto.tfvars
    rm -rf $base_working_dir/conf/*$component.auto.tfvars
}

function clean_up_configure() {
    local component=$1
    local base_working_dir=$2

    if [ -f "$base_working_dir/src/$component/$component.auto.tfvars" ]; then
        rm -rf $base_working_dir/src/$component/$component.auto.tfvars
    fi
}

function create_additional_user_domain_with_helm() { 
    local base_working_dir=$1

    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Create User domains"
    cd $base_working_dir/outputs/helm/

    while true
    do
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Wait for the previous init-container to finish."
        status=$(kubectl get po -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
        if [ "$status" == "Completed" ]; then
            helm uninstall root-domain 
            helm install user-domain -f user.yaml spaceone/spaceone-initializer
            break
        elif [ "$status" == "Failed" ] || [ "$status" == "Error" ] ; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Unable to process user domain creation.\n
                  The state of the initialization container of the root domain is "$status
            exit 1
        fi
        sleep 1
    done
    
    additional_domain_count=$(cat $base_working_dir/outputs/terraform_states/initialization.tfstate | jq '.outputs.additional_domain_count.value')
    user_domain=$(cat $base_working_dir/outputs/terraform_states/initialization.tfstate | jq '.outputs.domain_name.value' | sed 's/\"//g')
    if [ $additional_domain_count -gt 0 ]; then
        for ((i=1;i<=$additional_domain_count;i++))
        do
            sed 's/domain_name: '$user_domain'/domain_name: '$user_domain'-'$i'/g' user.yaml > user$i.yaml
            while true
            do
                echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Wait for the previous init-container to finish."
                status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
                if [ "$status" == "Completed" ]; then
                    helm uninstall user-domain
                    helm install user-domain -f user$i.yaml spaceone/spaceone-initializer
                    break
                elif [ "$status" == "Failed" ] || [ "$status" == "Error" ] ; then
                    echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Unable to process user domain creation.\n
                          The state of the initialization container of the previous user domain is "$status
                    exit 1
                fi
                sleep 1
            done
        done
    fi
}

function terraform_execute() {
    local component=$1
    local cmd=$2
    local base_working_dir=$3

    cd "$base_working_dir/src/$component"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Execute terraform $cmd in $component"
    terraform $cmd > /dev/null
    
    if [ $? -eq 1 ];then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Failed terraform $cmd in $component"
        exit 1
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Completed terraform $cmd in $component"
    fi
}

function build() {
    local components=("$@")
    local base_working_dir=$(pwd)

    for component in "${components[@]}";
    do
        ret=$( is_enable $component $base_working_dir )
        if [ $ret -ne 1 ];then
            configure $component $base_working_dir
            terraform_execute $component "init" $base_working_dir
            terraform_execute $component "plan" $base_working_dir
            terraform_execute $component "apply -auto-approve" $base_working_dir
            if [ $component == "initialization" ];then
                create_additional_user_domain_with_helm $base_working_dir
            fi
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] skip "$component
        fi
    done
}

function destroy() {
    local components=("$@")
    local base_working_dir=$(pwd)
    local len=${#components[@]}

    for ((i=$len -1; i>=0; i--))
    do
        ret=$( is_enable ${components[$i]} $base_working_dir )
        if [ $ret -ne 1 ];then
            terraform_execute ${components[$i]} "destroy -auto-approve" $base_working_dir
            clean_up_configure ${components[$i]} $base_working_dir
        else
            echo "skip "$component
        fi
    done
}

function main() {
    local main_arg=$1
    local components=( "certificate" "eks" "controllers" "deployment" "initialization" )
    
    if [ "$main_arg" = "build" ]; then
        build "${components[@]}"
    elif [ "$main_arg" = "destroy" ]; then
        destroy "${components[@]}"
    else
        echo "[ERROR] Invalid Option"
        exit 1
    fi
}

if [ "$1" = "" ]; then
    echo "Run the script as below"
    echo "sh install.sh { build | destroy }"
    exit  1
fi

main $1
