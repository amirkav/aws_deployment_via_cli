#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

### Install WSGI if it is not installed
# Ubuntu: sudo aptitude install libapache2-mod-wsgi
# RedHat: sudo yum install -y mod_wsgi
# macOS: pip install mod_wsgi  . Also see my notes below on how to modify httpd.conf
# Amazon Linux: need to install latest version manually. See amznlnx/05_install_wsgi.sh


# NOTE IF RUNNING ON MAC OS:
# If you are running the server on macOS using pip,
# then you need to add some directives to apache config
# file to load WSGI from its installed location on pip directory.
# Take output of this command and add it to the Apache configuration file to load the Apache module.
# $ mod_wsgi-express module-config
# Then add the output of the above module-config command to the end of the LoadModule section.
# $ sudo vim /private/etc/apache2/httpd.conf
# This step is not needed on Linux, because the installation
# will automatically add WSGI files to Apache directory path.

sudo yum install -y mod_wsgi

