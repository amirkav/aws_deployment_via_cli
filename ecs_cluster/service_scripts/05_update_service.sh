#!/bin/bash
exec > >(tee -a /var/log/service_init.log) 2>&1
source ${VENV_DIR}/bin/activate

cd ${GITS_DIR}/aurelius/ecs-cluster/service_scripts

# You can update a service's following attributes: task definition, desired-count, deployment configuration, network configuration.
aws ecs update-service --cluster ecs-cluster-${ENV}-${STACK_SUFFIX} --service ecs-service-${ENV}-${STACK_SUFFIX} --task-definition ecs-taskfam--${ENV}-${STACK_SUFFIX}

# https://docs.aws.amazon.com/cli/latest/reference/ecs/index.html#cli-aws-ecs
# https://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html
