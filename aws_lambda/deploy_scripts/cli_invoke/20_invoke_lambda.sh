#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

if [[ ${lambda_function_name} = *"scraper"* ]]; then
    lamb_type=scraper
    echo "scraper test event"
elif [[ ${lambda_function_name} = *"uploader"* ]]; then
    lamb_type=uploader
    echo "uploader test event"
else
    lamb_type=reporter
    echo "reporter test event"
fi

###################
### Invoke the lambda function
aws lambda invoke \
    --invocation-type Event \
    --function-name ${lambda_function_name} \
    --region us-west-2 \
    --payload file://${lambda_path}/../deploy_configs/test_event_${lamb_type}.json \
    --profile ${profile_user} \
    ${lambda_path}/../deploy_configs/output.log
