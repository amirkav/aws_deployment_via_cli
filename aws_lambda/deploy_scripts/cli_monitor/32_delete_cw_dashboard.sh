#!/bin/bash
exec > >(tee -a /tmp/log/deploy_scripts.log) 2>&1

### USAGE
# $ source ~/gits/lucius/deploy_scripts/cli_monitor/32_delete_cw_dashboards.sh -d $dinosaur

### RESOURCES
# https://aws.amazon.com/blogs/aws/new-api-cloudformation-support-for-amazon-cloudwatch-dashboards/
# https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/delete-dashboards.html

###################
export dash_name=dinosaur

# Override the above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -d | --dash-name )  shift
            dash_name=$1
            ;;
    esac
    shift
done
###################

#######################################
aws cloudwatch delete-dashboards \
    --dashboard-names ${dash_name}


