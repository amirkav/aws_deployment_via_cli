#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate
echo Running the uploader...

## If you are running manually, run the following two
# sudo su
# screen -LS <session_name>
source ${VENV_DIR}/bin/activate
python ${GITS_DIR}/seneca/uploader/dir_main.py
python ${GITS_DIR}/seneca/uploader/ar_main.py
python ${GITS_DIR}/seneca/uploader/drive_main.py


### to attach to an existing screen
# first get a list of all running screens and fetch the id of the screen you want to attach to
# $ sudo su
# $ screen -ls
# attach to the running screen
# $ screen -rd <screen_id or session_name>
