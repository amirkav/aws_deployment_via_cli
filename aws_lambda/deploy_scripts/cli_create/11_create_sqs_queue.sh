#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# NOTE: we create one SQS Queue per project, and do that when creating the VPC.
# So, there is no need to create a separate SQS Queue for each lambda in this workflow.
# This script is a placeholder in case this architecture changes and we decide
# to create a separate SQS Queue per lambda function.
# https://docs.aws.amazon.com/cli/latest/reference/sqs/create-queue.html

#TODO: automate the process of creating 11_create_sqs_queue_configs.json file

create_queue_response=$(aws sqs create-queue \
    --queue-name ${sqs_queue_name} \
    --attributes file://${GITS_DIR}/lucius/deploy_scripts/cli_create/11_create_sqs_queue_configs.json)

export queue_url=$(echo $create_queue_response | jq '.QueueUrl' | sed -e 's/"$//' -e 's/^"//')


## add tags to the queue
export tag_create_response=$(aws sqs tag-queue \
    --queue-url ${queue_url} \
    --tags Project=${project_name})

aws sqs list-queue-tags --queue-url ${queue_url}


## get queue ARN
export queue_attributes=$(aws sqs get-queue-attributes \
    --queue-url ${queue_url} \
    --attribute-names 'All')

export sqs_queue_arn=$(echo $queue_attributes | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')

