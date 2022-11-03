#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate
echo Installing the app from git repository...


### Install git and python packages
# Install git if it is not installed already
# https://stackoverflow.com/questions/5178292/pip-install-mysql-python-fails-with-environmenterror-mysql-config-not-found
sudo yum -y install gcc gcc-c++ kernel-devel
sudo yum -y install python-devel libxslt-devel libffi-devel openssl-devel
sudo yum -y install mysql mysql-devel mysql-common mysql-libs MySQL-python


### Clone and install our python codebase
# Note that the sudo here is to allow writing to that directory.
# You can connect to github with the default proxy and any user.
# Our assumption is that the app git repo is already cloned to /opt by bootstrap script before running deploy_all.sh
# sudo rm -rf ${GITS_DIR}
# sudo mkdir ${GITS_DIR}
# cd /opt
# sudo yum install -y git
# sudo -E git clone -b develop https://${GH_USER}:${GH_PASS}@github.com/amirkav/seneca.git

# install our package
cd ${GITS_DIR}
sudo -E ${VENV_DIR}/bin/pip install .


### Create directory to store model pickles and data
if [ ! -d "${DATA_DIR}" ]; then
    sudo mkdir -p ${DATA_DIR}
fi

