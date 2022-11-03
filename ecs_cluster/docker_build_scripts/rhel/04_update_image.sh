#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

# IMPORTANT NOTE: it is generally not recommended to commit changes
# to an image, without documenting those changes in the dockerfile.
# At any point in time, we should have transparency into how the
# container was put together. Therefore, if you want to update
# the application or the container, make the changes in the codebase
# and create a new image from refreshed codebase.
# The following pipeline (committing to an image and
# pushing to dockyard) should only be used for temporary changes.
# To create a new image from an update dockerfile (recommended),
# run the 03_create_image.sh script.


### Commit changes to an existing image on dockyard registry.
#TODO: add command line argument for version number
sudo docker commit -m "ready for testing" <container_id> seneca/seneca-api:v1.1
sudo docker login -u ${SSO_USER} -p ${SSO_PASS} dockyardaws.cloud.bbs.com
sudo docker push seneca/seneca-api:v1.1 dockyard.cloud.bbs.com/seneca/seneca-api:v1.1

