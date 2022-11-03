#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1


aws cloudformation deploy \
    --stack-name ${stack_name} \
    --template-file ${GITS_DIR}/lucius/templates/batch_jobs_serverless_cft.yaml \
    --parameter-overrides \
        FunctionName=${lambda_function_name} \
        Suffix=${suffix} \
        ProjectName=${project_name} \
        Env=${env} \
        SubnetIds=${subnet_ids} \
        SecurityGroupIds=${sg_ids} \
        SnsTopicName=${sns_topic_name} \
        SnsDlqTopicName=${sns_dlq_topic_name} \
        InvocationType=${invocation_type} \  #TODO: lambda-deployment currently does not support this. We can probably completely remove this variable and its conditional in CFT.
        LambdaS3Bucket=${s3_bucket} \
        LambdaS3Key=${s3_key} \
        LambdaHandler=${handler} \
        NotificationEmail=${notification_endpoint} \
        OwnerContact=${owner_contact} \
    --role-arn ${lambda_exec_role}

export lambda_arn=$(aws cloudformation describe-stacks \
    --stack-name ${stack_name} \
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' --output text)
