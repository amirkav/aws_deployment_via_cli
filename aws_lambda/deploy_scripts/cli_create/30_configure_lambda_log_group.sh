#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# https://stackoverflow.com/questions/45173145/can-we-set-cloudwatch-log-retention-days-in-etc-awslogs-awslogs-conf
# https://stackoverflow.com/questions/45364967/set-expiration-of-cloudwatch-log-group-for-lambda-function
# https://stackoverflow.com/questions/39231592/specify-log-group-for-an-aws-lambda

log_group_name = "/aws/lambda/"${lambda_function_name}
aws logs put-retention-policy \
    --log-group-name log_group_name \
    --retention-in-days 7
