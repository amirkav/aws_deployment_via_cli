#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate
echo Installing the app from git repository...


#######################################
### PIP INSTALL WITH AMAZON LINUX
# Amazon Linux machines can run both 32 and 64 bit programs.
# On such machines, pip installs some packages under the
# lib64/ directory, while installing other packages under lib/ directory.
# VENV_DIR/lib64/python2.7/site-packages
# VENV_DIR/lib/python2.7/site-packages

# This can cause problem for Python, if the lib64/ dir is not in python path.

# There are two solutions for this issue:
# (a) to force pip to install all packages under lib/ directory:
# $ pip install pandas --target=/opt/venv/lib/python2.7/site-packages
# (b) to add lib64/ directory to python path (recommended)
# >>> import sys; sys.path.append(VENV_DIR+'/lib64/python2.7/site-packages')

# We implement the second approach, because it is more compatible with how
# the default machine behavior of installing 64-bit packages in lib64/ dir.
# This way, even if we forget to include "--target" parameter in a pip call,
# the application will not break.
# https://github.com/pypa/pip/issues/4464

# This issue has been addressed by a Fedora patch and
# may be resolved in future Amazon Linux releases.
# So, remove the lib64/ addresses from sys.path assignment
# when it is no longer needed.
# https://bugs.python.org/issue1294959
#######################################

#######################################
### GCC INSTALL FOR NUMPY C DEPENDENCIES
# The Python package numpy is dependent on a number of C extensions.
# If a C extension is not installed on a Linux box, we may get errors such as
# "Importing the multiarray numpy extension module failed".
# To fix this issue, install GCC and other required C extensions first.
# https://github.com/numpy/numpy/issues/8653
#######################################

#######################################
### Install git and python packages
# Install git if it is not installed already
# https://stackoverflow.com/questions/5178292/pip-install-mysql-python-fails-with-environmenterror-mysql-config-not-found
sudo yum -y install gcc gcc-c++ kernel-devel
sudo yum -y install python-devel libxslt-devel libffi-devel openssl-devel
sudo yum -y install mysql mysql-devel mysql-common mysql-libs MySQL-python


### Clone and install our python codebase (optional)
# Our assumption is that the app git repo is already cloned to /opt by bootstrap script before running deploy_all.sh
# sudo rm -rf ${GITS_DIR}
# sudo mkdir ${GITS_DIR}
# cd /opt
# sudo yum install -y git
# sudo -E git clone -b develop https://${GH_USER}:${GH_PASS}@github.com/amirkav/seneca.git


### install our application package
cd ${GITS_DIR}
sudo -E ${VENV_DIR}/bin/pip install .


### Create directory to store model pickles and data
if [ ! -d "${DATA_DIR}" ]; then
    sudo mkdir -p ${DATA_DIR}
fi
