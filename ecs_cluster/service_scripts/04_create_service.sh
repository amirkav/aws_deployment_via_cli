#!/bin/bash
exec > >(tee -a /var/log/service_init.log) 2>&1
source ${VENV_DIR}/bin/activate

cd ${GITS_DIR}/aurelius/ecs-cluster/task_service_definitions

service_response=$(aws ecs create-service --service-name ecs-service-${ENV}-${STACK_SUFFIX} --cli-input-json file://./ecs_service_definition.json)
service_arn=$(echo $service_response | jq '.service.serviceArn' | sed -e 's/"$//' -e 's/^"//')


# https://docs.aws.amazon.com/cli/latest/reference/ecs/index.html#cli-aws-ecs
