#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

### Add env vars to docker config file,
# https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169
# Location of docker initialization config file:
# Ubuntu: /etc/default/docker
# RHEL: /etc/sysconfig/docker
# Amazon Linux: /etc/sysconfig/docker

sudo su
/bin/echo 'export VENV_DIR=/opt/venv' >> /etc/sysconfig/docker
/bin/echo 'export DATA_DIR=/opt/data' >> /etc/sysconfig/docker
/bin/echo 'export GITS_DIR=/opt/gits' >> /etc/sysconfig/docker
/bin/echo 'export CONF_DIR=/opt/.credentials' >> /etc/sysconfig/docker
exit

sudo /bin/systemctl restart docker.service
