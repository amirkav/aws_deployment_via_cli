#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

#TODO: version number??

### Restart docker ecs-service
# sudo systemctl restart systemd-hostnamed
sudo systemctl restart docker.service


### Create a container from the pulled image
sudo docker login -u ${SSO_USER} -p ${SSO_PASS} dockyardaws.cloud.bbs.com
sudo docker pull dockyard.cloud.bbs.com/seneca/seneca-api:0.1.0


### Start app with the following options
# -d : run in detached mode
# -w : set the working dir in the container
# -p : port forwarding
# docker image name
# no need to override CMD or ENTRYPOINT. The docker image will
# start Apache and Flask app for us (based on the dockerfile CMD line)
sudo docker run -d -w /home/ec2-user -p 5000:5000 seneca/seneca-api:v1.0
