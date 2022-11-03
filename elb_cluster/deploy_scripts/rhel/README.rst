
#######
Goals
#######
Non-dockerized script to deploy the Flask API and run our app.

In Dockerized deployment pattern, we have included these instructions
in the Dockerfile, and there is no need to run this script.


##############
Overview
##############
# The scripts in this directory do the following:
~ Install Python.
~ Install virtual environment on the server.
~ Install or clone your API codebase (ML model) via pip from github.
~ Install Python dependencies on it (import from S3 bucket).
~ Install Apache, WSGI services.
~ Setup Apache, WSGI servers.
~ Start an Apache server with WSGI.
~ Install a Flask API and open up a port.
~ Test API installation.


##############
Usage
##############
To quickly start the app on an EC2 instance:
- (AWS Console) Provision an ec2 instance with the proper properties
- SSH into the instance
$ sudo yum install -y git
$ sudo su
$ sudo git clone https://github.kdc.capitalone.com/cka694/seneca.git /opt
$ bash ${GITS_DIR}/aurelius/elb_cluster/deploy_scripts/rhel/00_deploy_all.sh


##############
Platform
##############
These scripts are written primarily for RHEL, which will also run on Amazon Linux AMIs.
When Ubuntu and macOS differ from RHEL, we have made comments to signal that deviation.
For macOS step-by-step instructions, see api_set_instructions.rst file.


##############
debugging
##############
$ apachectl configtest
$ systemctl status httpd.service
$ sudo vi /var/log/apache2/seneca-api-error_log
$ sudo apachectl restart


################################################
elb-cluster-cft.json
################################################
CloudFormation Template
Creates a ECS cluster, installs docker, pulls docker image of our app on it.
But, it does not start our application as a service on the cluster.
It also does not have a registrator.
