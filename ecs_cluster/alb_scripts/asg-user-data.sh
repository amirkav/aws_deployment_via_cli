#!/bin/bash
exec > >(tee -a /var/log/alb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log) 2>&1
set -o errexit -o nounset -o xtrace

#====== Set env vars ======
sudo /bin/echo 'export VENV_DIR=/opt/venv' >> /etc/environment
sudo /bin/echo 'export DATA_DIR=/opt/data' >> /etc/environment
sudo /bin/echo 'export GITS_DIR=/opt/gits' >> /etc/environment
sudo /bin/echo 'export CONF_DIR=/opt/.credentials' >> /etc/environment
sudo /bin/echo 'export ECS_CLUSTER=ecs-cluster-dev-seneca-4' >> /etc/environment
sudo /bin/echo \"export CONTAINER_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)\" >> /etc/environment
source /etc/environment

#====== INSTALL APPS & TOOLS ======
#=== Install & configure docker ===
sudo yum update && sudo yum install -y yum-utils
sudo yum install -y jq 2>&1
sudo yum-config-manager --enable rhui-us-west-2-rhel-server-extras
sudo yum install -y docker
sudo usermod -a -G docker ec2-user

#=== Install aws cli tool ===
sudo easy_install pip
sudo pip install --upgrade awscli


#====== CONFIGURE NETWORKING ======
#=== Allow the port proxy to route traffic using loopback addresses ===
sudo sh -c \"echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf\"
sudo sysctl -p /etc/sysctl.conf

#=== Enable IAM roles for tasks ===
sudo iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679

#=== Write the new iptables configuration ===
sudo sh -c 'iptables-save > /etc/sysconfig/iptables'


#====== CONFIGURE ECS AGENT ======
#=== Create the host volume mount points on your container instance ===
sudo mkdir -p /var/log/ecs /var/lib/ecs/data

#=== Create the /etc/ecs directory and ECS container agent configuration file ===
sudo mkdir -p /etc/ecs
sudo aws s3 cp s3://bbs-seneca-conf-pub/ecs.config /etc/ecs/ecs.config
sed -i.bak 's/${ECS_CLUSTER}/ecs-cluster-dev-seneca-4/g' /etc/ecs/ecs.config

#=== Create ecs-agent service file ===
sudo aws s3 cp s3://bbs-seneca-conf-pub/ecs-agent.service /etc/systemd/system/ecs-agent.service
sed -i.bak 's/${ECS_CLUSTER}/ecs-cluster-dev-seneca-4/g' /etc/systemd/system/ecs-agent.service

#=== Register the ecs agent as a daemon ===
sudo aws s3 cp s3://bbs-seneca-conf-pub/ecs-agent.timer /etc/systemd/system/ecs-agent.timer
sed -i.bak 's/${ECS_CLUSTER}/ecs-cluster-dev-seneca-4/g' /etc/systemd/system/ecs-agent.timer

#=== Make instance id and ip accessible for ecs agent ===
sudo curl -o /etc/local-ipv4 http://169.254.169.254/latest/meta-data/local-ipv4
sudo chmod a+r /etc/local-ipv4
sudo curl -o /etc/instance-id http://169.254.169.254/latest/meta-data/instance-id
sudo chmod a+r /etc/instance-id


#====== CREATE CLUSTER ======
aws ecs create-cluster --region us-west-2 --cluster-name ecs-cluster-dev-seneca-4


#====== CONFIGURE LOGGING and MONITORING ======
#====== Define volumes to mount into containers ======
sudo mkdir -p /var/log/seneca /var/lib/seneca/data /etc/seneca
sudo mkdir -p /etc/apache/conf /var/apache/html /etc/apache/conf.d

#====== Install and configure CloudWatch Logs agent for container instance logger ======
sudo yum install -y awslogs
sudo aws s3 cp s3://bbs-seneca-conf-pub/awslogs.conf /etc/awslogs/awslogs.conf
sudo sed -i -e \"s/{cluster}/${ECS_CLUSTER}/g\" /etc/awslogs/awslogs.conf
sudo sed -i -e \"s/{container_instance_id}/${CONTAINER_INSTANCE_ID}/g\" /etc/awslogs/awslogs.conf
sudo sed -i -e \"s/us-east-1/us-west-2/g\" /etc/awslogs/awscli.conf
sudo /bin/systemctl start awslogsd
sudo /bin/systemctl enable awslogsd.service
#sudo vi /var/log/awslogs.log

#=== Update awslogs configs for container logger ===
#sudo sed -i -e \"s/{cluster}/${ECS_CLUSTER}/g\" ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/awslogs_container.conf
#sudo sed -i -e \"s/{container_instance_id}/${CONTAINER_INSTANCE_ID}/g\" ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/awslogs_container.conf
#sudo cp ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/awslogs_container.conf ${GITS_DIR}/aurelius/ecs-cluster/dockerfile/amznlnx/awslogs_container.conf


#====== START ECS-AGENT ======
sudo /bin/systemctl --system daemon-reload
sudo /bin/systemctl enable lvm2-monitor.service
sudo /bin/systemctl enable lvm2-lvmetad.service

sudo /bin/systemctl enable docker.service
sudo /bin/systemctl enable ecs-agent.service
sudo /bin/systemctl start ecs-agent.timer
