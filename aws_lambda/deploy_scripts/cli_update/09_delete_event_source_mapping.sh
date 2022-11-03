#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# $ source ~/gits/lucius/deploy_scripts/cli_update/09_delete_event_source_mapping.sh -q $sqs_q_arn

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


#################
# delete an existing event source mapping
aws lambda delete-event-source-mapping \
    --uuid ${uuid}
