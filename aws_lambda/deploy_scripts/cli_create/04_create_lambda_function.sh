#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1


#######################################
### CREATE LAMBDA FUNCTION
# If you want to enable X-Ray, add the following parameter:
# --tracing-config Mode="Active" \

lambda_response=$(aws lambda create-function \
    --region us-west-2 \
    --function-name ${lambda_function_name} \
    --code S3Bucket=${s3_bucket},S3Key=${s3_key} \
    --role ${lambda_exec_role} \
    --environment Variables=${env_vars} \
    --handler ${handler} \
    --runtime python2.7 \
    --timeout 300 \
    --tracing-config Mode="Active" \
    --dead-letter-config TargetArn=${sns_dlq_topic_arn} \
    --memory-size 512 \
    --publish \
    --vpc-config file://${lambda_path}/../deploy_configs/vpc_configs.json \
    --tags "PROJECT_NAME=${project_name},ENV=${env}" \
    --profile ${profile_user})

# Note: the FunctionArn returned by 'create-function' command is unqualified ARN (does not include version number).
# An unqualified function ARN (a function ARN without a version or alias suffix) maps to the $LATEST version.
lambda_function_arn=$(echo $lambda_response | jq '.FunctionArn' | sed -e 's/"$//' -e 's/^"//')
lambda_function_version=$(echo $lambda_response | jq '.Version' | sed -e 's/"$//' -e 's/^"//')


#######################################
### PUBLISH A VERSION FOR THE LAMBDA FUNCTION
# See the following page for a workflow of working with version numbers and aliases to graduate a lambda function from DEV to PROD.
# https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases-walkthrough1.html
version_response=$(aws lambda publish-version \
    --region us-west-2 \
    --function-name ${lambda_function_name} \
    --profile ${profile_user})

# Note: the FunctionArn returned by 'publish-version' command is qualified ARN (includes version number).
lambda_function_arn=$(echo $version_response | jq '.FunctionArn' | sed -e 's/"$//' -e 's/^"//')
lambda_function_version=$(echo $version_response | jq '.Version' | sed -e 's/"$//' -e 's/^"//')


###################
### Create an alias for the function
alias_response=$(aws lambda create-alias \
    --region us-west-2 \
    --function-name ${lambda_function_name} \
    --description "Development version of the code" \
    --function-version ${lambda_function_version} \
    --name ${env} \
    --profile ${profile_user})

lambda_alias_arn=$(echo $alias_response | jq '.AliasArn' | sed -e 's/"$//' -e 's/^"//')

# Review list of versions and aliases
#aws lambda list-aliases --function-name ${lambda_function_name}
#aws lambda list-versions-by-function --function-name ${lambda_function_name}

# We can add another version to the alias to route traffic to it
# in a certain percentage of invocations (for A/B testing, limited PROD test, Blue/Green Deployment)
# https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html


#######################################
#######################################
#######################################
# DELETE THE LAMBDA FUNCTION
# aws lambda delete-function --function-name ${lambda_function_name}

