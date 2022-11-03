#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
# You can use either the qualified or unqualified ARN
# in your event source mapping to invoke the $LATEST version.
#######################################

sqs_q_arn=""
lambda_function_name=""

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


##################
# get a list of all event source mappings for a lambda function or an sqs queue
if [ sqs_q_arn != "" ]; then
    list_esm_resp=$(aws lambda list-event-source-mappings \
        --event-source-arn ${sqs_q_arn})
else
    list_esm_resp=$(aws lambda list-event-source-mappings \
        --function-name ${lambda_function_name}:${env})
fi

echo "event source mappings: ${list_esm_resp}"
uuid=$(echo $list_esm_resp | jq '.EventSourceMappings[].UUID' | sed -e 's/"$//' -e 's/^"//')
echo "updating uuid ${uuid}"


##################
### Update an existing event source mapping
# You dont need to update event source mapping if you are using alias,
# and if your alias is still referring to your preferred lambda version.
# Only run this command if the lambda function name or its alias has changed,
# and you want to keep the old CW Event Rule but apply it to the updated lambda.
# https://docs.aws.amazon.com/lambda/latest/dg/aliases-intro.html

aws lambda update-event-source-mapping \
    --uuid ${uuid} \
    --function-name ${lambda_function_name}:${env} \
    --enabled

