#!/bin/bash
exec > >(tee -a /var/log/service_init.log) 2>&1
source ${VENV_DIR}/bin/activate

cd ${GITS_DIR}/aurelius/ecs-cluster/service_scripts

# First, find the service you are looking for
aws ecs list-services --cluster ecs-cluster-${ENV}-${STACK_SUFFIX}

# Then, see service status
aws ecs describe-services --cluster ecs-cluster-${ENV}-${STACK_SUFFIX} --services ecs-service-${ENV}-${STACK_SUFFIX}

# Then, set the service desired task to zero. You can delete a service if you have no running tasks in it and the desired task count is zero.
aws ecs update-service --cluster ecs-cluster-${ENV}-${STACK_SUFFIX} --service <service_name> --desired-count 0

# Finally, delete the service
aws ecs delete-service --cluster ecs-cluster-${ENV}-${STACK_SUFFIX} --service <service_name>


# https://docs.aws.amazon.com/cli/latest/reference/ecs/index.html#cli-aws-ecs
