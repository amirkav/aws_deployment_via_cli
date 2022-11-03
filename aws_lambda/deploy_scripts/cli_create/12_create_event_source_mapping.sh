#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
# This command requires the following permission: lambda:CreateEventSourceMapping
# Need to create an SQS queue before using this command.

# You can use either the qualified or unqualified ARN
# in your event source mapping to invoke the $LATEST version.

## CLI, API, CloudFormation guides
# https://docs.aws.amazon.com/cli/latest/reference/lambda/create-event-source-mapping.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-eventsourcemapping.html
# https://docs.aws.amazon.com/lambda/latest/dg/API_CreateEventSourceMapping.html

## Lambda tutorial
# https://docs.aws.amazon.com/lambda/latest/dg/with-sqs-configure-sqs.html

# Lambda integration with SQS
# https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html

## Bash script
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
# https://unix.stackexchange.com/questions/23961/how-do-i-exit-a-script-in-a-conditional-statement
# https://stackoverflow.com/questions/3822621/how-to-exit-if-a-command-failed/3822709
#######################################

while [ "$1" != "" ]; do
    case $1 in
        -q | --sqs-q-arn ) shift
            sqs_q_arn=$1
                                ;;
        -l | --lambda-function-name ) shift
            lambda_function_name=$1
                                ;;
    esac
    shift
done


event_source_mapping_response=$(aws lambda create-event-source-mapping \
    --event-source-arn ${sqs_q_arn} \
    --function-name ${lambda_function_name}:${env} \
    --batch-size 1
    )
