#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

export stack_suffix=01
export env=dev
cd ${GITS_DIR}/db_deployer/mysql/templates

aws cloudformation create-stack --stack-name CfnParamStore-${env}-${stack_suffix} \
    --template-body file://./cfn-param-store.yml \
    --capabilities CAPABILITY_IAM
