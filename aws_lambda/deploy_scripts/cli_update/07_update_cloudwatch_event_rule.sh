#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# Note: aws events API does not have a "update rule" command.
# To update an existing CW Events Rule, use the put-rule command,
# and provide the same name as before. CloudWatch will automatically
# update the existing rule.
# https://docs.aws.amazon.com/cli/latest/reference/events/index.html#cli-aws-events
# https://docs.aws.amazon.com/cli/latest/reference/events/list-rules.html
# https://docs.aws.amazon.com/cli/latest/reference/events/describe-rule.html
# https://docs.aws.amazon.com/cli/latest/reference/events/list-targets-by-rule.html


#######################################
cw_events_rule_name=${project_name}-${env}-CWEventRule-${base_name}-${application}-${suffix}
lambda_arn=arn:aws:lambda:us-west-2:474602133305:function:${lambda_function_name}:${env}
rule_id=${lambda_function_name}_${env}

while [ "$1" != "" ]; do
    case $1 in
        -n | --event-rule-name ) shift
            cw_events_rule_name=$1
                                ;;
        -l | --lambda-arn ) shift
            lambda_arn=$1
                                ;;
        -i | --target-id ) shift
            target_id=$1
                                ;;
    esac
    shift
done
#######################################


aws events list-rules \
    --name-prefix ${project_name}-${env}

aws events describe-rule \
    --name ${cw_events_rule_name}

aws events list-rule-names-by-target \
    --target-arn ${lambda_arn}

list_targets_resp=$(aws events list-targets-by-rule \
    --rule ${cw_events_rule_name})
target_id_2=$(echo $list_targets_resp | jq '.Targets[].Id' | sed -e 's/"$//' -e 's/^"//')

aws events remove-targets \
    --rule ${cw_events_rule_name} \
    --ids target_id

