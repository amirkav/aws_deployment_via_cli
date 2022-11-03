#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1


#######################################
export base_name=dev-box
export suffix=02
export project_name=sorena  # this will determine which VPC to deploy the cluster into
export env=dev

# Override the above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -b | --base_name )      shift
                                base_name=$1
                                ;;
        -s | --suffix )         shift
                                suffix=$1
                                ;;
        -p | --project_name )   shift
                                project_name=$1
                                ;;
        -e | --env )            shift
                                env=$1
                                ;;
    esac
    shift
done
#######################################

export subnet_ids=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.subnets_public" --raw-output | sed -e 's/"$//' -e 's/^"//')
export subnet_id=$(echo $subnet_ids | cut -d',' -f1)

export sg_ids_publ=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_public" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids_priv=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_public" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids_wtls=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_whitelist" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids=${sg_ids_publ}','${sg_ids_wtls}

export ami_id=$(cat ${CONF_DIR}/config.json | jq ".common.ami_lambda" --raw-output | sed -e 's/"$//' -e 's/^"//')

export sns_topic_name=${base_name}"-sns-"${suffix}
export notification_endpoint=devops@altitudenetworks.com

export iam_exec_role=arn:aws:iam::474602133305:role/BBS-Dev-RDS-CloudFormation-Role
export profile_user=amir
