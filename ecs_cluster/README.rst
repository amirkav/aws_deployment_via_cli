


###########################
docker_build_scripts
###########################
One-off scripts to create the docker image for the first time
(or update an existing one) and push it to RCR for future use.


###########################
dockerfile
###########################
DockerFile for the one-off container creation.
Only need it when we create a new image or update an existing one.


###########################
task_service_definitions
###########################
Config files for ECS agent, registrator, etc.
These files are uploaded to S3, and bootstrap scripts
will download and read them from S3. They are
included here for reference.


###########################
templates
###########################
CloudFormation templates to start an ECS cluster that manages
a cluster of services, each running an instance of seneca.


###########################
management_scripts
###########################
Python scripts to manage cloudformation stack, ecs service, aws resources.
Most of these capabilities are already available using aws cli and bash scripts.
The scripts in this directory automate those for CI/CD purposes.


