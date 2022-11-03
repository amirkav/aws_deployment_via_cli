#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate


### Install WSGI if it is not installed
# Ubuntu: sudo aptitude install libapache2-mod-wsgi
# RedHat: sudo yum install -y mod_wsgi
# macOS: pip install mod_wsgi  . Also see my notes under macOS dir on how to modify httpd.conf
# Amazon Linux: need to install latest version manually. See amznlnx/05_install_wsgi.sh


### WHY WE NEED MANUAL INSTALLATION FOR WSGI IN AMAZON LINUX:
# The mod_wsgi package that comes with Amazon Linux distro is old and is configured for Python 2.6.

# The main problem with that is that the older WSGI versions do not support
# the parameter "python-home" in WSGIDaemonProcess directive.
# As a result, we cannot point WSGI to use the Python installation under our preferred virtual env.
# This creates package inconsistencies among other problems.

# In short, we need to use newer WSGI releases that support python 2.7 and later.
# To do that, we need to download the package manually and install, as explained below.

# Read the following posts for more on why we need the latest WSGI version:
# https://stackoverflow.com/questions/42726493/trying-to-get-django-running-on-a-vps-but-i-keep-running-into-invalid-option-to
# https://stackoverflow.com/questions/37265358/configure-python-path-using-mod-wsgi

# Read the following posts on why Amazon Linux does not have the latest mod_wsgi:
# https://forums.aws.amazon.com/thread.jspa?threadID=111364
# https://aws.amazon.com/amazon-linux-ami/2017.03-packages/


### HOW TO INSTALL WSGI MANUALLY
# http://modwsgi.readthedocs.io/en/develop/user-guides/quick-installation-guide.html
# http://modwsgi.readthedocs.io/en/develop/user-guides/installation-issues.html
# https://github.com/GrahamDumpleton/mod_wsgi/releases


### install requirements
# apxs is a tool for building and installing extension modules for the Apache.
# We can install apxs by installing httpd-devel
# https://serverfault.com/questions/728735/apache-mod-wsgi-installation-error
# https://stackoverflow.com/questions/16854750/issues-installing-mod-wsgi-cannot-find-makefile-in
# Ubuntu/Debian: sudo apt-get install apache2-dev
# We have already installed the following when installing httpd (apache) itself. So no need to repeat here again.
# sudo yum -y install httpd-devel
# sudo yum -y install httpd mod_ssl


### download mod_wsgi and install manually
cd ~
wget https://github.com/GrahamDumpleton/mod_wsgi/archive/4.5.23.tar.gz
tar xvzf 4.5.23.tar.gz
cd mod_wsgi-4.5.23/


### configure by pointing to python and apache installations
# sudo ./configure --with-python="${VENV_DIR}/bin/python" --with-apxs=/usr/sbin/httpd
sudo ./configure --with-python="${VENV_DIR}/bin/python"
sudo make
sudo make install

echo "LoadModule wsgi_module modules/mod_wsgi.so" >> /etc/httpd/conf.d/wsgi.conf
