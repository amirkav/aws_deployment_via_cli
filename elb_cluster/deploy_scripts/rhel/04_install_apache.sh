#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

### Install Apache if it is not installed on your instance
sudo yum install -y httpd mod_ssl


### Review config file and update codebase
# If you have SSH access, review the following settings in http.conf file.
# We will use these settings in the rest of our code,
# so we may need to modify other parts of our
# codebase to be consistent with Apache settings.
# Most of these settings are OS-specific,
# so as long as you move this codebase to
# a new machine on the same OS, you don't need to
# make any changes to other parts of your code.

# Location of the Apache config file:
# RedHat: vi /etc/httpd/conf/httpd.conf

## RHEL
# ServerRoot "/etc/httpd"
# DocumentRoot "/var/www/html"
# ErrorLog "logs/error_log"
# ServerName <ip_address or FQN>:<port_number>
# Listen 80
# Include conf.modules.d/*.conf
# IncludeOptional conf.d/*.conf
# User apache
# Group apache
