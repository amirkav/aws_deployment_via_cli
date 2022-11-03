#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
### Update the Lambda function
# NOTE: Update lambda codebase on S3 before running this code.

# NOTE: If you are using the versioning feature,
# this command by default will update the $LATEST version of your Lambda function.
# You can force the create-function or update-function-code requests
# to publish a version by adding the optional 'publish' parameter in the request
# It is recommended to publish a new version with each update:
# https://docs.aws.amazon.com/cli/latest/reference/lambda/update-function-code.html
# If you publish a new version, remember to update the lambda alias to point to the new version.

lambda_update_response=$(aws lambda update-function-code \
    --function-name ${lambda_function_name} \
    --s3-bucket=${s3_bucket} \
    --s3-key=${s3_key} \
    --publish
    )

export lambda_function_version=$(echo $lambda_update_response | jq '.Version' | sed -e 's/"$//' -e 's/^"//')


#######################################
#lambda_function_name=dinosaur-dev-lambda-drive-scraper-users-orch-06
#lambda_function_name=dinosaur-dev-lambda-drive-scraper-files-orch-06
#lambda_function_name=dinosaur-dev-lambda-drive-scraper-worker-06
#lambda_function_name=dinosaur-dev-lambda-master-uploader-06
#lambda_update_resp=$(aws lambda update-function-configuration \
#    --function-name ${lambda_function_name} \
#    --memory-size 1728)
#echo $lambda_update_resp
