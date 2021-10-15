#!/bin/bash
BASE_WORKING_DIR=$(pwd)

function help_txt() {
    echo "NAME:"
    echo " SpaceONE lanchpad"
    echo " "
    echo "SYNOPSIS:"
    echo " docker run ... -c cmd [-t type]"
    echo " "
    echo "ARGS:"
    echo " -c cmd           {install|destroy|upgrade} SpaceONE"
    echo "    install"
    echo "    destroy"
    echo "    upgrade"
    echo " "
    echo " -t type          Choosing a installation type Enterprise or Development"
    echo "    ent (default)"
    echo "    dev"
    echo " "
    echo " -h               Display help"
    echo " "
    echo "EXAMPLES:"
    echo " docker run ... -c install -t ent"
    echo " docker run ... -c install -t dev"
    echo " docker run ... -c destroy"
    echo " docker run ... -c upgrade"
    exit 0
}

function generate_gpg_key () {
    gpg --no-tty --batch --gen-key <<EOF
%echo Generating a key type RSA
Key-Type: RSA
Subkey-Type: RSA
Name-Real: spaceone
Name-Comment: Encrypt Your AWS Secrets
Name-Email: gpg@spaceone.org
Expire-Date: 2
Passphrase: spaceone
%commit
%echo done
EOF

    gpg --output $BASE_WORKING_DIR/src/secret/gpg/public-key-binary.gpg --export gpg@spaceone.org
}

function config_aws_credentais () {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] config aws credentials "

    mkdir $HOME/.aws
    cat $BASE_WORKING_DIR/conf/aws_credential > $HOME/.aws/credentials

    export TF_VAR_region=$( grep region $BASE_WORKING_DIR/conf/aws_credential | cut -d"=" -f2 | tr -d ' ' )
}

function generate_tfvars () {
    local component=$1

    if [[ $component =~ certificate|eks|documentdb|initialization|deployment ]]; then
        cp $BASE_WORKING_DIR/conf/$component.conf $BASE_WORKING_DIR/src/$component/$component.auto.tfvars
    fi
}

function set_kubectl_config () {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] set kubectl config"

    export KUBECONFIG=$BASE_WORKING_DIR/outputs/eks_config/config
}

function clean_up_application() {
    helm uninstall -n spaceone user-domain > /dev/null
    rm -rf $BASE_WORKING_DIR/outputs/helm/spaceone-initializer/*

    helm uninstall -n spaceone spaceone > /dev/null
    sleep 5
    kubectl delete ns root-supervisor > /dev/null
    kubectl delete ns spaceone > /dev/null
    rm -rf $BASE_WORKING_DIR/outputs/helm/spaceone/*

    clean_up_configure "deployment"
    clean_up_configure "initialization"
}

function clean_up_configure() {
    local component=$1

    if [ -f "$BASE_WORKING_DIR/src/$component/$component.auto.tfvars" ]; then
        rm -rf $BASE_WORKING_DIR/src/$component/$component.auto.tfvars
    fi

    if [ -f "$BASE_WORKING_DIR/outputs/terraform_states/$component.tfstate" ]; then
        rm -rf $BASE_WORKING_DIR/outputs/terraform_states/$component.tfstate*
    fi
}

function terraform_execute() {
    local component=$1
    local cmd=$2

    cd "$BASE_WORKING_DIR/src/$component"
    echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Execute terraform $cmd in $component"
    terraform $cmd
    
    if [ $? -eq 1 ];then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Failed terraform $cmd in $component"
        exit 1
    fi
}

function destroy() {
    local components=( "certificate" "eks" "controllers" "documentdb" "secret" )
    local len=${#components[@]}

    clean_up_application
    for ((i=$len -1; i>=0; i--))
    do
        if [ -f $BASE_WORKING_DIR/outputs/terraform_states/${components[$i]}.tfstate ]; then
            terraform_execute ${components[$i]} "destroy -auto-approve"
            clean_up_configure ${components[$i]}
        fi
    done

    if [ -f $BASE_WORKING_DIR/src/secret/gpg/public-key-binary.gpg ]; then
        rm  -rf $BASE_WORKING_DIR/src/secret/gpg/public-key-binary.gpg
    fi
}

function build() {
    local components=("$@")

    for component in "${components[@]}";
    do
        if [[ $component =~ deployment|initialization ]]; then
            set_kubectl_config
        fi
        generate_tfvars $component
        terraform_execute $component "init" 
        terraform_execute $component "plan" 
        terraform_execute $component "apply -auto-approve"
    done
}

function get_components() {
    local type=$1

    if [ ! $type ] || [ $type == "ent" ]; then
        echo "certificate" "eks" "controllers" "documentdb" "secret" "deployment" "initialization"
    elif [ $type == "dev" ];  then
        echo "certificate" "eks" "controllers" "deployment" "initialization"
    else
        exit 1
    fi
}

function set_install_type() {
    local type=$1

    if [ ! $type ] || [ $type == "ent" ]; then
        export TF_VAR_enterprise=true
    elif [ $type == "dev" ];  then
        export TF_VAR_development=true
    else
        exit 1
    fi
}

function main() {
    # If no arguments are passed, an error is raised.
    if [ ! $1 ];then
        echo "No args"
        help_txt
    fi

    while getopts c:t:h arg
    do
        case "$arg" in
            c) cmd=$OPTARG;;
            t) type=$OPTARG;;
            h) help_txt;;
            *) echo "Unsupport argument" exit 1;;
        esac
    done

    config_aws_credentais

    if [ $cmd == "install" ]; then
        components=($( get_components $type ))
        set_install_type $type
        generate_gpg_key
        build "${components[@]}"
    elif [ $cmd == "destroy" ]; then
        set_kubectl_config
        destroy
    elif [ $cmd == "upgrade" ]; then
        set_kubectl_config
        # update helm chart
        kubectl config set-context $(kubectl config current-context) --namespace spaceone
        helm repo add spaceone https://spaceone-dev.github.io/charts
        helm repo update
        BASE_WORKING_DIR_sed=$( echo $BASE_WORKING_DIR | sed -e  's/\//\\\//g' )
        helm upgrade spaceone $( for value_file in `ls $BASE_WORKING_DIR/outputs/helm/spaceone`; do echo $value_file | sed -e "s/^/-f $BASE_WORKING_DIR_sed\/outputs\/helm\/spaceone\//g"; done ) spaceone/spaceone
    else
        echo "Unsupport command"
        exit 1
    fi
}

main $*
