#!/bin/bash
exec > >(tee -a /var/log/service_init.log) 2>&1
source ${VENV_DIR}/bin/activate

cd ${GITS_DIR}/aurelius/ecs-cluster/task_service_definitions

###################
### Specify parameters and variables
export STACK_PREFIX=ecs-stack
export STACK_SUFFIX=seneca-18
export ENV=dev
export SUBNET_1=subnet-02fa0570d0c5dd119
export SUBNET_2=subnet-f3e6f595
export SG_1=sg-2a252856
export SG_2=sg-35f5f949
export VPC_ID=vpc-d4c914ad


###################
### Register a Task Definition.
td_response=$(aws ecs register-task-definition --family ecs-taskfam-${ENV}-${STACK_SUFFIX} --cli-input-json file://./ecs_task_definition.json)
td_arn=$(echo $td_response | jq '.taskDefinition.taskDefinitionArn' | sed -e 's/"$//' -e 's/^"//')

# https://docs.aws.amazon.com/cli/latest/reference/ecs/index.html#cli-aws-ecs
