#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
### Orchestrator script for all scripts in this directory.

# cd /opt/gits/aurelius/elb_cluster/deploy_scripts/rhel

# Setup the python virtual environment
bash 01_install_virtenv.sh

# Install model
bash 02_install_model.sh

# Train model
# bash 03_train_model.sh

# Install Apache web server. Not needed if running the dockerfile.
bash 04_install_apache.sh

# Install WSGI. Not needed if running the dockerfile.
bash 05_install_wsgi.sh

# Permissions and symlinks
bash 06_set_permissions.sh

# Spin up Apache server. Not needed if running the dockerfile.
bash 07_start_apache.sh
