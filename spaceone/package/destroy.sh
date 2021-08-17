#!/bin/sh

# function delete_route53_record() {
#     local base_working_dir=$1

#     hosted_zone_id=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.zone_id.value')
#     console_domain=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_domain.value')
#     console_api_domain=$(cat $base_working_dir/outputs/terraform_states/certificate.tfstate | jq '.outputs.console_api_domain.value')

#     aws route53 list-resource-record-sets \
#     --hosted-zone-id $hosted_zone_id |
#     jq -c '.ResourceRecordSets[]' |
#     while read -r resourcerecordset
#     do
#     read -r name Name <<<$(echo $(jq -r '.Name,.Name' <<<"$resourcerecordset"))
#     if [ $Name == $console_domain ] || [ $Name == $console_api_domain ]; then
#         aws route53 change-resource-record-sets \
#         --hosted-zone-id $hosted_zone_id \
#         --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":
#             '"$resourcerecordset"'
#             }]}' \
#         --output text --query 'ChangeInfo.Id'
#     fi
#     done
# }

function clean_up_application() {
    local component=$1

    if [ $component == "initialization" ];then
        helm uninstall -n spaceone user-domain > /dev/null
    elif [ $component == "deployment" ];then
        helm uninstall -n spaceone spaceone > /dev/null
        kubectl delete ns root-supervisor > /dev/null
        kubectl delete ns spaceone > /dev/null
    fi

}

function clean_up_configure() {
    local component=$1
    local base_working_dir=$2

    if [ -f "$base_working_dir/src/$component/$component.auto.tfvars" ]; then
        rm -rf $base_working_dir/src/$component/$component.auto.tfvars
    fi

    if [ $(ls $base_working_dir/outputs/helm/spaceone-initializer/ | grep user | wc -l)  -gt 0 ]; then
        rm -rf $base_working_dir/outputs/helm/spaceone-initializer/user*.yaml
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

function is_enable() {
    local component=$1
    local base_working_dir=$2

    case $component in
        deployment|initialization)
                    conf_dir="$base_working_dir/conf/application/$component.conf"
                    ;;
        certificate|eks|controllers)
                    conf_dir="$base_working_dir/conf/infrastructure/$component.conf"
                    ;;
    esac

    is_enable=$(cat $conf_dir | grep 'enable =' | cut -d'=' -f2 | cut -d'"' -f2)
    if [ $is_enable == "false" ]; then
        echo 1
    elif [ $is_enable == "true" ]; then
        echo 0
    fi
}

function destroy() {
    local components=("$@")
    local base_working_dir=$(pwd)
    local len=${#components[@]}

    for ((i=$len -1; i>=0; i--))
    do
        ret=$( is_enable ${components[$i]} $base_working_dir )
        if [ $ret -ne 1 ];then
            clean_up_application ${components[$i]}
            terraform_execute ${components[$i]} "destroy -auto-approve" $base_working_dir
            clean_up_configure ${components[$i]} $base_working_dir
        fi
    done
}

function main() {
    local components=( "certificate" "eks" "controllers" "deployment" "initialization" )
    
    destroy "${components[@]}"
}

main
