#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

if [ $# -gt 0 ]; then
    image_tag=$1
else
    image_tag=1.1
fi

### Copy files that will be referenced in DockerFile to dockerfile directory
sudo cp ${GITS_DIR}/aurelius/elb_cluster/deploy_scripts/amznlnx/seneca-api.conf ${GITS_DIR}/aurelius/ecs-cluster/dockerfile/amznlnx/seneca-api.conf
sudo cp ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/awslogs_container.conf ${GITS_DIR}/aurelius/ecs-cluster/dockerfile/amznlnx/awslogs_container.conf
sudo cp ${GITS_DIR}/aurelius/ecs-cluster/logging_configs/supervisord.conf ${GITS_DIR}/aurelius/ecs-cluster/dockerfile/amznlnx/supervisord.conf


### Build a new image from Dockerfile
cd ${GITS_DIR}/aurelius/ecs-cluster/dockerfile/amznlnx
sudo docker build -t seneca-image:${image_tag} -f dockerfile .


### Note: Running a container
# Dont run the container manually, unless you want to manage the service yourself.
# Our goal from creating the container is to push it to ECR, and
# then create task-definition and ECS services that automatically
# scale the application up&down using the container.
# But, if you want to debug the container, you can run it using the following command:
# $ sudo docker run -d -p 8081:80 --name=seneca-cont seneca-image:${image_tag}


### push the image to dockyard registry
# log in to AWS ECR
# export ecr_login=$(sudo aws ecr get-login --region us-west-2 --registry-ids 137112412989 --no-include-email)
export ecr_login=$(sudo aws ecr get-login --region us-west-2 --registry-ids 474602133305 --no-include-email)
sudo ${ecr_login}

# tag the docker image
sudo docker tag seneca-image:${image_tag} 474602133305.dkr.ecr.us-west-2.amazonaws.com/seneca:${image_tag}

# Push the image
sudo docker push 474602133305.dkr.ecr.us-west-2.amazonaws.com/seneca:${image_tag}
# troubleshooting:
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/common-errors-docker.html#error-403

