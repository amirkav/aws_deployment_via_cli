#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

# WSGI is basically a virtual host running on Apache.
# Therefore, to register WSGI, we need to
# (a) create a config file for it, and
# (b) have the main Apache process to include that vhost in its setup.
# Apache allows adding vhosts by putting their config files under
# Apache's root directory under a subdirectory such as
#   Ubuntu: "others/" or "sites-available/"
#   RHEL: "conf.modules.d/"
#   Amazon Linux: "conf.d/"
# We can this directory the "vhost directory".
# Thus, we also need to put WSGI config file in vhost directory,
# and also make sure that in the Apache's main config file (httpd.conf),
# we have a line such as "Include <vhost_dir>".

# Note: On some platforms, we can put symlinks in Apache server's vhost directory to
# point to the vhost.conf file under our codebase. But, some platforms such as macOS
# do not allow putting symlinks under Apache root dir. To be consistent across all
# platforms, we physically copy the vhost.conf file to vhost directory.
# The effect is that seneca-api.conf will be physically copied to /etc/httpd/conf.d/
# but, seneca-api.wsgi will be linked to the seneca installation dir.


### Copy configuration file into apache dir
sudo cp ${GITS_DIR}/aurelius/elb_cluster/deploy_scripts/rhel/seneca-api.conf /etc/httpd/conf.modules.d/
sudo chmod 755 /etc/httpd/conf.modules.d/


### (Step 2) Create log directory
sudo mkdir -p /var/log/apache2/


### (Step 3) Restart server
sudo apachectl restart
# sudo /bin/systemctl restart apache.ecs-service


### DEBUGGING:
# apachectl configtest
# systemctl status httpd.ecs-service
# sudo vi /var/log/apache2/seneca-api-error_log
