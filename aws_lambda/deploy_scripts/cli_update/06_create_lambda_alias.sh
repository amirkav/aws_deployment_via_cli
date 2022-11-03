#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# This is used for staging and production, as well as for A/B testing.
# https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html
# https://docs.aws.amazon.com/lambda/latest/dg/aliases-intro.html

# https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases-walkthrough1.html
# https://docs.aws.amazon.com/cli/latest/reference/lambda/create-alias.html

# If you need to point to $LATEST, use the following format:
# --function-version "\$LATEST"

#######################################
while [ "$1" != "" ]; do
    case $1 in
        -l | --lambda-function-name )  shift
            lambda_function_name=$1
            ;;
        -v | --lambda-function-version )  shift
            lambda_function_version=$1
            ;;
        -a | --alias )  shift
            alias=$1
            ;;
    esac
    shift
done
#######################################

aws lambda create-alias \
    --region us-west-2 \
    --function-name ${lambda_function_name} \
    --function-version ${lambda_function_version} \
    --name ${alias} \
    --profile ${profile_user}



