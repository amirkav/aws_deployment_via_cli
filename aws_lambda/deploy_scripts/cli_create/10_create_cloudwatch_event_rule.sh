#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# set up a rule to run an AWS Lambda function on a schedule
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/RunLambdaSchedule.html
# https://docs.aws.amazon.com/cli/latest/reference/events/index.html
# https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html#cli-aws-lambda

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
        -a | --application ) shift
            export application=$1
                                ;;
        -l | --lambda-name )    shift
            lambda_function_name=$1
                                ;;
        -c | --cron-expression )    shift
            cron_expression=$1
                                ;;
    esac
    shift
done

export cw_events_rule_name=${project_name}-${env}-CWEventRule-${base_name}-${application}-${suffix}
export lambda_path=${GITS_DIR}/lucius/lucius/$(echo ${base_name} | tr "-" "_" )

#######################################
### Step 1: Create a CloudWatch Events Rule
# https://docs.aws.amazon.com/cli/latest/reference/events/put-rule.html
## with cron expression
events_rule_response=$(aws events put-rule \
    --name ${cw_events_rule_name} \
    --schedule-expression "${cron_expression}")

cw_rule_arn=$(echo $events_rule_response | jq '.RuleArn' | sed -e 's/"$//' -e 's/^"//')

## with rate expression
#events_rule_response=$(aws events put-rule \
#    --name ${lambda_function_name} \
#    --schedule-expression 'rate(1 minute)')
#
#cw_rule_arn=$(echo $events_rule_response | jq '.RuleArn' | sed -e 's/"$//' -e 's/^"//')


#######################################
### Step 2: Add permission for the CW Event to trigger the Lambda function
# https://docs.aws.amazon.com/cli/latest/reference/events/put-permission.html

# Note: if you specify a value for '--qualifier' parameter,
# then the permission applies only when request is made using qualified function ARN.
# https://docs.aws.amazon.com/cli/latest/reference/lambda/add-permission.html
# https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases-walkthrough1.html#versioning-permissions-cli
# https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases-permissions.html

add_perm_response=$(aws lambda add-permission \
    --function-name ${lambda_function_name} \
    --qualifier ${env} \
    --statement-id ${cw_events_rule_name}_permission_${suffix}_$(echo `date '+%Y%m%d-%H%M%S'`) \
    --action 'lambda:InvokeFunction' \
    --principal events.amazonaws.com \
    --source-arn ${cw_rule_arn})


#######################################
### Step 3: Add the Lambda function as a Target of the CW Event Rule
# https://docs.aws.amazon.com/cli/latest/reference/events/put-targets.html

# Step 3-a: create the targets config file
IFS='' read -r -d '' input_string <<EOL
"{
\"project_name\": \"${project_name}\",
\"application\": \"${application}\",
\"user_email\": \"${user_email}\",
\"gdpr_compliant\": \"${gdpr_compliant}\",
\"filter_for_sensitive_parents\": \"${filter_for_sensitive_parents}\",
\"sns_topic_arn\": \"arn:aws:sns:us-west-2:474602133305:${sns_topic_name}\",
\"sqs_q_url_uploader\": \"${sqs_q_url_uploader}\",
\"sqs_q_url_drive_users\": \"${sqs_q_url_drive_users}\",
\"sqs_q_url_drive_files\": \"${sqs_q_url_drive_files}\",
\"sqs_q_url_admin_reports\": \"${sqs_q_url_admin_reports}\",
\"sqs_q_url_dir_users\": \"${sqs_q_url_dir_users}\",
\"sqs_q_url_dir_tokens\": \"${sqs_q_url_dir_tokens}\"
}"
EOL

cat >${deploy_configs_path}/targets.json <<EOL
[
  {
    "Arn": "arn:aws:lambda:us-west-2:474602133305:function:${lambda_function_name}:${env}",
    "Id": "${lambda_function_name}_${env}",
    "Input": $(echo ${input_string})
  }
]
EOL


# step 3-b assign the target to the event rule
put_target_resp=$(aws events put-targets \
    --rule ${cw_events_rule_name} \
    --targets file://${lambda_path}/../deploy_configs/targets.json)


#######################################
#######################################
#######################################
### DELETE EVENTS TRIGGER AND RULE
### Step 1: delete the targets associated with the rule
#aws events remove-targets \
#    --rule ${cw_events_rule_name} \
#    --ids ${lambda_function_name}


###################
### Step 2: delete the rule
#aws events delete-rule --name ${cw_events_rule_name}

