#!/bin/bash

# Add the following to "Command" parameter of the container definition in task definition:
# RUN ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/awslogs_logstream_name.sh
# OR, directly include the following lines in the supervisord.conf file (this is what I did)

export CONTAINER_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export CLUSTER_ID=$(curl -s http://localhost:51678/v1/metadata | jq .Cluster |  sed -e 's/^"//' -e 's/"$//')

sudo sed -i -e "s/{container_instance_id}/${CONTAINER_INSTANCE_ID}/g" /var/awslogs/etc/awslogs.conf
sudo sed -i -e "s/{cluster}/${CLUSTER_ID}/g" /var/awslogs/etc/awslogs.conf

