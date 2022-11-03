#!/bin/bash
exec > >(tee -a /var/log/service_init.log) 2>&1
source ${VENV_DIR}/bin/activate

cd ${GITS_DIR}/aurelius/ecs-cluster/service_scripts

aws ecs deregister-task-definition --task-definition ecs-taskfam--seneca-4
