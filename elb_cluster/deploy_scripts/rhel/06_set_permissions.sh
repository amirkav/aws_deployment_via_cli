#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

### Create symlink in server root dir, to API config folder where .wsgi file is stored.
# The Apache server needs to exeucte .wsgi file. But, it cannot execute files
# outside its root dir. This symlink will enable apache server to execute .wsgi file.
sudo rm -rf /var/www/html/seneca-api
sudo ln -sT ${GITS_DIR}/aurelius/elb_cluster/deploy_scripts/rhel /var/www/html/seneca-api


### Change ownership of the symlink.
sudo chown -R apache /var/www/html/seneca-api


### Change group and permissions of the html dir so that the server can read html pages
sudo chgrp -R apache /var/www/html
sudo chmod -R 775 /var/www/html


### Change group and permissions of the full virtual environment dir so Apache can run any Python module.
sudo chgrp -R apache ${VENV_DIR}
sudo chmod -R 775 ${VENV_DIR}


### Change group and permissions of the API dir so Apache can run our Python repo.
sudo chgrp -R apache ${GITS_DIR}
sudo chmod -R 775 ${GITS_DIR}


### Change group and permissions of the data dir so Apache can read/write data and results.
sudo chgrp -R apache ${DATA_DIR}
sudo chmod -R 775 ${DATA_DIR}
