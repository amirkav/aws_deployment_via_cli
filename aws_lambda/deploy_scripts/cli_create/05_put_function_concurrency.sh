#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1


#######################################
concurrency_limit=50

# Override above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -l | --lambda-function-name )  shift
            lambda_function_name=$1
            ;;
        -c | --concurrency-limit )  shift
            concurrency_limit=$1
            ;;
    esac
    shift
done
#######################################

aws lambda put-function-concurrency \
    --function-name ${lambda_function_name} \
    --reserved-concurrent-executions ${concurrency_limit}
