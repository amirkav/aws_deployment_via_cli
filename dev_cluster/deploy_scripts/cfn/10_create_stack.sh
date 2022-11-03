#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

aws cloudformation create-stack \
    --stack-name ${project_name}-${env}-${base_name}-${suffix} \
    --template-body file://${GITS_DIR}/aurelius/dev_cluster/templates/dev_cluster_cft_amznlnx.json \
    --parameters \
        ParameterKey=BaseName,ParameterValue=${base_name} \
        ParameterKey=Suffix,ParameterValue=${suffix} \
        ParameterKey=ProjectName,ParameterValue=${project_name} \
        ParameterKey=Env,ParameterValue=${env} \
        ParameterKey=SubnetId,ParameterValue=\'${subnet_id}\' \
        ParameterKey=SecurityGroupIds,ParameterValue=\'${sg_ids}\' \
        ParameterKey=AmiId,ParameterValue=${ami_id} \
        ParameterKey=SnsTopicName,ParameterValue=${sns_topic_name} \
        ParameterKey=OwnerContact,ParameterValue=${notification_endpoint} \
    --role-arn ${iam_exec_role}
