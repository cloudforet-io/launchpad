#!/bin/sh

function terraform_execute(){
    local component=$1
    local cmd=$2
    local base_working_dir=$3

    cd "$base_working_dir/$component"
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
        terraform_execute $component "init" $base_working_dir
        terraform_execute $component "plan" $base_working_dir
        terraform_execute $component "apply -auto-approve" $base_working_dir
    done
}

function destroy() {
    local components=("$@")
    local base_working_dir=$(pwd)
    local len=${#components[@]}

    for ((i=$len -1; i>=0; i--))
    do
        terraform_execute ${components[$i]} "destroy -auto-approve" $base_working_dir
    done
}

function main() {
    components=( "certificate" "eks" "controllers" "deployment" "initialization" )
    
    if [ "$1" = "build" ]; then
        build "${components[@]}"
    elif [ "$1" = "destroy" ]; then
        destroy "${components[@]}"
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Invalid Option"
        exit 1
    fi
}

if [ "$1" = "" ]; then
    echo "Run the script as below"
    echo "sh install.sh { build | destroy }"
    exit  1
fi

main $1
