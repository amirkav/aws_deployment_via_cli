#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

#TODO: add a cli parameter to accept version number.

### Build a new image from Dockerfile and push it to dockyard registry.
cd /opt/gits/aurelius/ecs-cluster/dockerfile
sudo docker build -t seneca/seneca-api:v1.0 -f dockerfile .
sudo docker login -u ${SSO_USER} -p ${SSO_PASS} dockyardaws.cloud.bbs.com
sudo docker push seneca/seneca-api:v1.0 dockyard.cloud.bbs.com/seneca/seneca-api:v1.0
