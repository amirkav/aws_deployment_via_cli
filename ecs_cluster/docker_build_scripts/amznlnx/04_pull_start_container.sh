#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

### USAGE:
# This script is mostly used for troubleshooting of docker containers.
# In the live app, the ECS Service (specifically, ecs-agent) is in charge of
# monitoring and spinning up new containers as they become needed.
# So, we never have to manually run a docker image in the live app.
# To run this script, use the template "elb-cluster-...", not "ecs-cluster-...".


### pull the image from dockyard registry
# log in to AWS ECR
export ecr_login=$(sudo aws ecr get-login --region us-west-2 --registry-ids 474602133305 --no-include-email)
sudo ${ecr_login}

sudo docker pull 474602133305.dkr.ecr.us-west-2.amazonaws.com/seneca:1.0

sudo docker run -d -p 8081:80 --name=seneca-cont 474602133305.dkr.ecr.us-west-2.amazonaws.com/seneca:1.0

