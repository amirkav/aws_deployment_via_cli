#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# The python module for lambda function starts by downloading
# config.json file and other dependencies into CONF_DIR.
# SAM Local runs inside a docker container and does not
# have permissions to write to $HOME dir. As a result,
# the download command inside python may throw the following:
# module initialization error: [Errno 13] Permission denied: '/Users'
# To avoid that error, change the env vars inside the script to
# point to a writable directory such as /tmp
# NOTE: Dont change other env vars such as VENV_DIR and GITS_DIR because
# they need to reference to actual virtual environments and files on drive.
export CONF_DIR='/tmp'


# With SAM Local, we simply invoke the application,
# which both deploys and invokes the application in one go.
#TODO: Pass on parameter overrides when sam local supports it: https://github.com/awslabs/aws-sam-cli/issues/572
#TODO: Update the template to use !Ref and other CFN intrinsic functions: https://github.com/awslabs/aws-sam-cli/issues/573
# For now, we have added them as "Default" values to template parameters.
sam local invoke "LambdaFunction" \
    --template ${GITS_DIR}/lucius/templates/batch_jobs_samlocal_cft.yaml \
    --event ${lambda_path}/deploy_configs/test_event.json \
    --env-vars ${lambda_path}/deploy_configs/env_vars.json \
    --log-file ${lambda_path}/deploy_configs/output.log \
    --profile=${profile_user} \
    --debug



sam local invoke "LambdaFunction" \
    --template ${GITS_DIR}/lucius/templates/batch_jobs_serverless_cft.yaml \
    --event ${lambda_path}/deploy_configs/test_event.json \
    --env-vars ${lambda_path}/deploy_configs/env_vars.json \
    --log-file ${lambda_path}/deploy_configs/output.log \
    --profile=${profile_user} \
    --debug
