#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

### Set environmental variables
# Our assumption is that the UserData script has already set these env vars.
# This is just a reminder to make sure we have set these vars.
# export VENV_DIR="/opt/venv"
# export DATA_DIR="/opt/data"
# export GITS_DIR="/opt/gits"
# export CONF_DIR="/opt/.credentials"

# Setup the python virtual environment
sudo yum install -y python-setuptools
sudo easy_install virtualenv

sudo rm -rf ${VENV_DIR}
sudo -E virtualenv ${VENV_DIR}

sudo chmod -R 775 ${VENV_DIR}
source ${VENV_DIR}/bin/activate


# Install packages
sudo -E ${VENV_DIR}/bin/pip install --upgrade pip
# We have included these in requirements.txt file, so dont need them here anymore.
# sudo -E ${VENV_DIR}/bin/pip install numpy scipy pandas sklearn flask flask-WTF
