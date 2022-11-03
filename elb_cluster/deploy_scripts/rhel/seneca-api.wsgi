"""
This script is the entry point for the Flask API.
The wsgi daemon loads this file using the system's python binary (e.g., /usr/bin/python).

We switch to the virtual environment, and add API directory to system path.
Finally, we start the Flask API by importing its main module.

Apache will execute this file upon its startup.
Therefore, this file needs to be placed in a directory owned
by apache, and with proper permissions for apache to execute it.
To satisfy that requirement, we place a symlink
from apache's root dir to the directory containing this script.
"""

import sys
import os
print("sys.executable: {}".format(sys.executable))
print("os.__file__: {}".format(os.__file__))
print("sys.path before activating venv: {}".format(sys.path))

### set environmental variables
VENV_DIR = "/opt/venv"
DATA_DIR = "/opt/data"
GITS_DIR = "/opt/gits"
CONF_DIR = "/opt/.credentials"

os.environ['VENV_DIR'] = VENV_DIR
os.environ['DATA_DIR'] = DATA_DIR
os.environ['GITS_DIR'] = GITS_DIR
os.environ['CONF_DIR'] = CONF_DIR


### Activate the virtual env so we can use installed packages
activate_this = VENV_DIR+'/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))
print("sys.path after activating venv: {}".format(sys.path))


### Add API python directory to system path, so we can import API's modules in python
sys.path.append(VENV_DIR+"/lib/python2.7/site-packages/seneca/api")


### Start Flask App
from seneca.api._api import app as application
