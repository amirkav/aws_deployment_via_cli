#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

###################
# https://docs.aws.amazon.com/lambda/latest/dg/deploying-lambda-apps.html

# ---------------------------------------------------------------
# Option a: use 'sam deploy' aka 'aws cloudformation deploy'
# ---------------------------------------------------------------
# to create a CloudFormation stack based on the SAM template we created.
# https://github.com/awslabs/aws-sam-cli/blob/develop/README.rst#package-and-deploy-to-lambda

# 'sam deploy' is identical to 'aws cloudformation deploy' command.
# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html
#https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-cli-deploy.html

# This is the best option for continuous integration and development,
# because it does not start everything from scratch. Instead, if we
# pass the name of an existing stack to it, it will create a change-set
# and only update / create components that need change.


# ---------------------------------------------------------------
# Option b: use 'aws cloudformation create-stack'
# ---------------------------------------------------------------
# This option is best when we want to create a fresh stack from scratch.
# It also creates a few extra parameters that can be used to control
# stack behavior and cloudformation behavior.


# ---------------------------------------------------------------
# Option c: use 'aws lambda create-function'
# ---------------------------------------------------------------
# See scripts under lucius/deploy_scripts/cli_create
# to create lambda function and its dependents individually.
# This option is different from options a&b in that
# it creates different pieces of the lambda function individually.

# This option is best for development & testing environments when
# we need to experiment with different components, and want to
# have close monitoring and control in every step of the way.
###################


###################
# 'sam package' command will zip your code artifacts, upload to S3 and
# produce a SAM file that is ready to be deployed to Lambda using AWS CloudFormation.
# We already do most of this using '01_sam_package_lambda.sh' script.

# 'sam deploy' command will deploy the packaged SAM template to CloudFormation.
# Both 'sam package' and 'sam deploy' are identical to their AWS CLI equivalents commands:
# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html
# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html
###################

#TODO: Move this to its own script / workflow step
#sam validate \
#    --template ${GITS_DIR}/lucius/templates/batch_jobs_serverless_cft.yaml \
#    --debug


aws cloudformation deploy \
    --stack-name ${stack_name} \
    --template-file ${GITS_DIR}/lucius/templates/batch_jobs_serverless_cft.yaml \
    --parameter-overrides \
        FunctionName=${lambda_function_name} \
        Suffix=${suffix} \
        ProjectName=${project_name} \
        Env=${env} \
        SubnetIds=${subnet_ids} \
        SecurityGroupIds=${sg_ids} \
        SnsTopicName=${sns_topic_name} \
        SnsDlqTopicName=${sns_dlq_topic_name} \
        InvocationType=${invocation_type} \  #TODO: lambda-deployment currently does not support this. We can probably completely remove this variable and its conditional in CFT.
        LambdaS3Bucket=${s3_bucket} \
        LambdaS3Key=${s3_key} \
        LambdaHandler=${handler} \
        NotificationEmail=${notification_endpoint} \
        OwnerContact=${owner_contact} \
    --role-arn ${lambda_exec_role}

export lambda_arn=$(aws cloudformation describe-stacks \
    --stack-name ${stack_name} \
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' --output text)
