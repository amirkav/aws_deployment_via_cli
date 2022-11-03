#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate


### Option 1: Install using the installer script
# sudo mkdir -p /var/lib/awslogs/
# cd ${GITS_DIR}/aurelius/ecs-cluster/logging_configs
# python ./awslogs-agent-setup.py -n -r us-west-2 -c ./awslogs_container.conf


### Option 2: install awslogs manually
sudo yum install -y awslogs
sudo aws s3 cp s3://bbs-seneca-conf-pub/awslogs.conf /etc/awslogs/awslogs.conf
sudo sed -i -e "s/{cluster}/${ECS_CLUSTER}/g" /etc/awslogs/awslogs.conf
sudo sed -i -e "s/{container_instance_id}/${CONTAINER_INSTANCE_ID}/g" /etc/awslogs/awslogs.conf
sudo sed -i -e "s/us-east-1/us-west-2/g" /etc/awslogs/awscli.conf
sudo /bin/systemctl start awslogsd
sudo /bin/systemctl enable awslogsd.service
