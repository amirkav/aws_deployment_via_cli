
##########
USAGE
##########

================
Deployment
================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/management_scripts

Create a new cluster:
$ python 01_create_stack.py -b ecs-stack -c ecs-cluster -e dev -u seneca-11

Get stack status
- by cluster name:
$ python 02_get_stack_info.py -m get_stack_status -c ecs-cluster-dev-seneca-11 -r 'us-west-2'
- by stack name:
$ python 02_get_stack_info.py -m get_stack_status -s ecs-stack-dev-seneca-11 -r 'us-west-2'

Update an existing stack
$ python 03_update_stack.py --s ecs-stack-dev-seneca-12

Delete an existing stack
$ python 05_delete_stack.py -s ecs-stack-dev-seneca-12 -r 'us-west-2'


================
Monitoring
================
Get a list of container instances in a cluster:
$ aws ecs list-container-instances --cluster ecs-cluster-dev-seneca-12 --filter "attribute:ecs.instance-type matches t2.*"
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html

############################################
Python scripts for AWS resource management
############################################
The scripts in this directory automate the process of managing AWS resources,
using python-based modules.

Note that most of these tasks can be done using AWS CLI.
But, as we manage more resources such as clusters, we need to
automate their management automatically. Especially, when
using CI/CD, we need a central platform to monitor and manage
our stack. Python is a good platform for that purpose.
Therefore, it makes sense to write a wrapper around stack
creation and management.

Furthermore, trying to change stack parameters through
the CFT template can be intimidating and error-prone.
The cluster_settings.yml file in this directory filters down
the stack parameters to a subset of the most important ones
and allows us to change them in a more user-friendly way.
This is what this directory is trying to achieve,

The Stack will run an ECS Service, with Application Load Balancer
and Autoscaling Group.


===================
01_create_stack.py
===================
A script to start an ECS-optimized stack.

The stack parameters are determined from the following sources:

(a) ecs-cluster-cft.json
    The core source of parameters is the CFT file, where
    we specify most of the hard-coded core parameters.

(b) service-settings.yml
    Some parameters that need to be changed by users
    are stored in a config file called service-settings.yml

(c) Command-line arguments:
    Parameters that may need to be changed per stack creation
    are included command line arguments.
    These command line arguments override service-settings.yml parameters, including:
    basename: stack_base_name : stack_basename
    environment: dev, qa, prod
    aws_region: AWS region
    ami-id
    ecs-service-name
    service-port
    owner-contact
    stack-suffix
    folder-suffix
    ecs-service-name: Name of ecs service
    newrelic-license
    image-name: full path to ecs-agent online registry
    aws_profile: AWS instance Profile (IAM Role)
    cluster-name

    Note: The default values for most of the command-line arguments are read
    from the settings file. This means that these parameters are read
    from the settings file unless they are override by a command line input.


(d) Jenkinsfile
    In addition to above, Jenkinsfile can also change the parameters on the fly.
    Jenkinsfile calls create-stack.sh shell script
    and passes some command-line arguments to it.
    These command line arguments are hard-coded in the Jenkinsfile.
    From create-stack.sh script, these command line arguments are passed to
    create-cluster.py file.

    Note: We dont call create-cluster.py directly. Instead, we have the
    Jenkinsfile call create-stack.sh file, which in turn calls
    create-cluster.py script with command line arguments.
    When Jenkinsfile calls create-stack.sh script, it will also pass on
    some command-line arguments to it.
    So, to change default values of command-line arguments,
    change their values in the Jenkinsfile.

(e) Template scripts
    We can still change stack parameters on the fly using
    template scripts (e.g., jinja2) to modify CFTs and Jenkinsfiles.

#TODO: make sure argument names are consistent across jenkinsfile, create-cluster.sh, create-cluster.py, service-settings.yml, ecs-cluster-cft.json

We have three different behaviors for reading stack parameters:
a- Some parameters are read directly from settings file; e.g., ask, CMDBEnvironment, ECSAgentImageName, ECSClusterName, ExtraPackagesFileName.
b- Some parameters are read from command-line arguments, but their default values are from the settings file; e.g., environment, service_name, folder_suffix, owner_contact, stack_basename. I.e., they are read from the settings file unless they are override by a command line input.
c- Some parameters are calculated by the entry point of create_stack script or inside main() method; e.g., keypair_name, ami_id, provisioning_bucket, provisioning_folder.


-----------
Stack name
-----------
Stack name has the following pattern:
{stack_basename}-{environment}-{stack_suffix}
All three parameters above can be overriden from the command line.


=====================
02_get_stack_info.py
=====================


===================
03_update_stack.py
===================
It provides a user-faced script to update an ECS-optimized stack.


===========================
04_update_provisioning.py
===========================
Deprecated. I dont use provisioning directories on S3, so this code is not needed.


=====================
05_delete_stack.py
=====================



=============
Resources
=============
CloudFormation best practices:
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html





