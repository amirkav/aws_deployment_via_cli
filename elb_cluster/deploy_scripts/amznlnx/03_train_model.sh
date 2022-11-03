#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1
source ${VENV_DIR}/bin/activate

# Get training data into the directory by:
# scp from your local machine to ~/
# Then, copy to the python lib:

sudo cp ~/model.pkl ${VENV_DIR}/lib/python2.7/site-packages/seneca/tests/data/

# Train seneca
sudo ${VENV_DIR}/bin/python -c "from seneca import main; main.validate()"

