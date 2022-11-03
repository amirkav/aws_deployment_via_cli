#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

# https://docs.docker.com/engine/installation/linux/docker-ee/rhel/
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html-single/getting_started_with_containers/
# https://forums.aws.amazon.com/thread.jspa?messageID=555865


### Install docker
sudo yum install -y yum-utils
sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
sudo yum install -y docker


### Start docker
# in ubuntu: sudo ecs-service docker start
sudo systemctl start docker.service

# Configure Docker to start on boot
sudo systemctl enable docker.service


### Other post-install steps
# https://docs.docker.com/engine/installation/linux/linux-postinstall/#configure-docker-to-start-on-boot
# sudo groupadd docker
# sudo usermod -aG docker $USER

### Debugging
# systemctl status docker.ecs-service
