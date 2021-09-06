#!/bin/bash
BASE_WORKING_DIR=$(pwd)

function add_aws_credentais () {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] add aws_credentials"

    if [ ! -d "$HOME/.aws" ]; then
        mkdir $HOME/.aws
    fi

    if [ -f "$HOME/.aws/credentials" ]; then
        touch $HOME/.aws/credentials
    fi

    echo  " " >> $HOME/.aws/credentials
    cat $BASE_WORKING_DIR/conf/aws_credential >> $HOME/.aws/credentials

    export AWS_PROFILE=spaceone_dev
}

function check_os_type () {
    case "$OSTYPE" in
        darwin*)  echo "OSX" ;; 
        linux*)   echo "LINUX" ;;
        *)        echo "unknown: $OSTYPE"; exit 1 ;;
    esac
}

function check_prerequisite () {
    local OS_TYPE=$( check_os_type )

    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] check prerequisite"

    is_jq=$( command -v jq )
    if [ ! $is_jq ]; then
        if [[ "$OS_TYPE" =~ OSX ]]; then
            brew install jq
        elif [[ "$OS_TYPE" =~ LINUX ]]; then
            linux_distro=$( awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '\"' | cut -d " " -f 1 )
            if [[ "$linux_distro" =~ Ubuntu ]]; then
                sudo apt-get install jq -y
            elif [[ "$linux_distro" =~ CentOS ]]; then
                sudo yum install jq -y
            fi
        fi
    fi

    is_unzip=$( command -v unzip )
    if [ ! $is_unzip ]; then
        if [[ "$OS_TYPE" =~ OSX ]]; then
            brew install unzip
        elif [[ "$OS_TYPE" =~ LINUX ]]; then
            linux_distro=$( awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '\"' | cut -d " " -f 1 )
            if [[ "$linux_distro" =~ Ubuntu ]]; then
                sudo apt-get install unzip -y
            elif [[ "$linux_distro" =~ CentOS ]]; then
                sudo yum install unzip -y
            fi
        fi
    fi

    is_aws_cli=$( command -v aws )
    if [ ! $is_aws_cli ]; then
        if [[ "$OS_TYPE" =~ OSX ]]; then
            brew install awscli
        elif [[ "$OS_TYPE" =~ LINUX ]]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
            unzip /tmp/awscliv2.zip -d /tmp
            sudo /tmp/aws/install
        fi
    fi

    is_aws_iam_authenticator=$( command -v aws-iam-authenticator )
    if [ ! $is_aws_iam_authenticator ]; then
        if [[ "$OS_TYPE" =~ OSX ]]; then
            brew install aws-iam-authenticator
        elif [[ "$OS_TYPE" =~ LINUX ]]; then
            curl "https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator" -o "/tmp/aws-iam-authenticator"
            chmod +x /tmp/aws-iam-authenticator
            mv /tmp/aws-iam-authenticator /usr/local/bin
        fi
    fi

    # set aws credentials
    add_aws_credentais
}

function set_configure() {
    local component=$1

    case $component in
        deployment|initialization)
                    part="application"
                    ;;
        certificate|eks|controllers)
                    part="infrastructure"
                    ;;
    esac

    case $component in
        controllers) 
                    domain_name=$(cat $BASE_WORKING_DIR/outputs/terraform_states/certificate.tfstate | jq '.outputs.domain_name.value')
                    eks_cluster_name=$(cat $BASE_WORKING_DIR/outputs/terraform_states/eks.tfstate | jq '.outputs.cluster_id.value')
                    cluster_oidc_issuer_url=$(cat $BASE_WORKING_DIR/outputs/terraform_states/eks.tfstate | jq '.outputs.cluster_oidc_issuer_url.value' | sed 's/\//\\\//g')
                    
                    sed 's/domain_name = ""/domain_name = '$domain_name'/g' $BASE_WORKING_DIR/conf/$part/$component.conf > $BASE_WORKING_DIR/conf/$part/tmp.$component.auto.tfvars
                    sed 's/eks_cluster_name = ""/eks_cluster_name = '$eks_cluster_name'/g' $BASE_WORKING_DIR/conf/$part/tmp.$component.auto.tfvars > $BASE_WORKING_DIR/conf/$part/tmp1.$component.auto.tfvars
                    sed 's/cluster_oidc_issuer_url = ""/cluster_oidc_issuer_url = '$cluster_oidc_issuer_url'/g' $BASE_WORKING_DIR/conf/$part/tmp1.$component.auto.tfvars > $BASE_WORKING_DIR/conf/$part/$component.auto.tfvars
                    ;;
        deployment)
                    console_api_domain=$(cat $BASE_WORKING_DIR/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_api_domain.value')
                    console_api_certificate_arn=$(cat $BASE_WORKING_DIR/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_api_certificate_arn.value' | sed 's/\//\\\//g')
                    console_domain=$(cat $BASE_WORKING_DIR/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_domain.value')
                    console_certificate_arn=$(cat $BASE_WORKING_DIR/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_certificate_arn.value' | sed 's/\//\\\//g')

                    sed 's/console_api_domain = ""/console_api_domain = '$console_api_domain'/g' $BASE_WORKING_DIR/conf/$part/$component.conf > $BASE_WORKING_DIR/conf/$part/tmp1.$component.auto.tfvars
                    sed 's/console_api_certificate_arn = ""/console_api_certificate_arn = '$console_api_certificate_arn'/g' $BASE_WORKING_DIR/conf/$part/tmp1.$component.auto.tfvars > $BASE_WORKING_DIR/conf/$part/tmp2.$component.auto.tfvars
                    sed 's/console_domain = ""/console_domain = '$console_domain'/g' $BASE_WORKING_DIR/conf/$part/tmp2.$component.auto.tfvars > $BASE_WORKING_DIR/conf/$part/tmp3.$component.auto.tfvars
                    sed 's/console_certificate_arn = ""/console_certificate_arn = '$console_certificate_arn'/g' $BASE_WORKING_DIR/conf/$part/tmp3.$component.auto.tfvars > $BASE_WORKING_DIR/conf/$part/$component.auto.tfvars
                    ;;
        *)
                    cp $BASE_WORKING_DIR/conf/$part/$component.conf $BASE_WORKING_DIR/conf/$part/$component.auto.tfvars
                    ;;
    esac

    sed '1d' $BASE_WORKING_DIR/conf/$part/$component.auto.tfvars > $BASE_WORKING_DIR/src/$component/$component.auto.tfvars
    rm -rf $BASE_WORKING_DIR/conf/$part/*$component.auto.tfvars
}

function create_additional_user_domain_with_helm() { 
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Creating User domains"
    cd $BASE_WORKING_DIR/outputs/helm/spaceone-initializer/
    
    user_domain_count=$(cat $BASE_WORKING_DIR/outputs/terraform_states/initialization.tfstate | jq '.outputs.user_domain_count.value')
    user_domain=$(cat $BASE_WORKING_DIR/outputs/terraform_states/initialization.tfstate | jq '.outputs.domain_name.value' | sed 's/\"//g')
    if [ $user_domain_count -gt 0 ]; then
        for ((i=1;i<=$user_domain_count;i++))
        do
            while true
            do
                status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
                if [ $status == "Completed" ]; then
                    if [ $i -eq 1 ]; then
                        helm uninstall -n spaceone root-domain
                    else
                        helm uninstall -n spaceone user-domain
                    fi
                    sed 's/domain_name: '$user_domain'/domain_name: '$user_domain'-'$i'/g' user.yaml > user$i.yaml
                    helm install user-domain -f user$i.yaml spaceone/spaceone-initializer
                    break
                elif [ $status == "Failed" ] || [ "$status" == "Error" ] ; then
                    echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Unable to process user domain creation.\n
                          The state of the initialization container of the previous user domain is "$status
                    exit 1
                fi
                echo "Wait for the init-container to finish......"
                sleep 1
            done
        done
    fi
}

function terraform_execute() {
    local component=$1
    local cmd=$2

    cd "$BASE_WORKING_DIR/src/$component"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Execute terraform $cmd in $component"
    terraform $cmd > /dev/null
    
    if [ $? -eq 1 ];then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Failed terraform $cmd in $component"
        exit 1
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Completed terraform $cmd in $component"
    fi
}

function is_enable() {
    local component=$1

    case $component in
        deployment|initialization)
                    conf_dir="$BASE_WORKING_DIR/conf/application/$component.conf"
                    ;;
        certificate|eks|controllers)
                    conf_dir="$BASE_WORKING_DIR/conf/infrastructure/$component.conf"
                    ;;
    esac

    is_enable=$(cat $conf_dir | grep 'enable =' | cut -d'=' -f2 | cut -d'"' -f2)
    if [ $is_enable == "false" ]; then
        echo 1
    elif [ $is_enable == "true" ]; then
        echo 0
    fi
}

function build() {
    local components=("$@")

    for component in "${components[@]}";
    do
        ret=$( is_enable $component )
        if [ $ret -ne 1 ];then
            set_configure $component 
            terraform_execute $component "init" 
            terraform_execute $component "plan" 
            terraform_execute $component "apply -auto-approve" 

            if [ $component == "initialization" ];then
                create_additional_user_domain_with_helm
            fi
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Skip build "$component
        fi
    done
}

function main() {
    local components=( "certificate" "eks" "controllers" "deployment" "initialization" )

    check_prerequisite
    build "${components[@]}"
}

main
