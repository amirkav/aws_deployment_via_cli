
This dir contains config files used to:
- set up ecs-agent on EC2 containers,
- define task definitions in ECS,
- define task discovery agents in ECS,
- define ECS services,

The config files are uploaded to S3.
The UserData section of CFTs has instructions to
pull the config files from S3 during bootstrap phase.
Make sure these files are regularly uploaded to S3.


#####################################
USAGE
#####################################

=================================
To start a new ECS cluster
=================================
$ export stack_suffix=seneca-11
$ export env=dev
$ cd ${GITS_DIR}/aurelius/ecs-cluster/templates
$ aws cloudformation create-stack --stack-name ecs-stack-${env}-${stack_suffix} --template-body file://./ecs-cluster-cft-amznlnx.json --parameters ParameterKey=BaseName,ParameterValue=ecs-stack ParameterKey=StackSuffix,ParameterValue=${stack_suffix}


==================================
To update ECS agent configs on S3
==================================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/task_service_definitions
$ aws s3 cp ./ecs-agent.service s3://bbs-seneca-conf-pub/ecs-agent.service --sse="AES256"
$ aws s3 cp ./ecs.config s3://bbs-seneca-conf-pub/ecs.config --sse="AES256"
$ aws s3 cp ./ecs-agent.timer s3://bbs-seneca-conf-pub/ecs-agent.timer --sse="AES256"


==================================
To update log configs on S3
==================================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/logging_configs
$ aws s3 cp ./awslogs.conf s3://bbs-seneca-conf-pub/awslogs.conf --sse="AES256"


========================================
To start a task using task definition
========================================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/task_service_definitions

---------------------
register the task
---------------------
# register the task with cluster
$ aws ecs register-task-definition --family seneca-taskdef-02 --cli-input-json file://./ecs_task_definition.json

---------------------
run task
---------------------
# run task (dont do this if you want to define a Service)
$ aws ecs run-task --cluster ecs-cluster-dev-seneca-14 --task-definition seneca-taskdef-02 --count 3

------------------------------------------
run task with constraints and strategy
------------------------------------------
# add constraints to "run task" command
$ aws ecs run-task --cluster ecs-cluster-dev-seneca-14 --task-definition seneca-taskdef-02 --count 3 --placement-constraints type="memberOf",expression="(attribute:ecs.instance-type == t2.small or attribute:ecs.instance-type == t2.medium) and attribute:ecs.availability-zone == us-west-2a"

# add constraints to "run task" command
$ aws ecs run-task --cluster ecs-cluster-dev-seneca-14 --task-definition seneca-taskdef-02 --count 3 --placement-constraints type="memberOf",expression="(attribute:ecs.instance-type == t2.small or attribute:ecs.instance-type == t2.medium) and attribute:ecs.availability-zone == us-west-2a"

# add strategies to "run task" command
$ aws ecs run-task --cluster ecs-cluster-dev-seneca-14 --task-definition seneca-taskdef-02 --count 3 --placement-strategy type="spread",field="attribute:ecs.availability-zone" type="binpack",field="memory"

------------------------------------------
get task status
------------------------------------------
# to get the status of a task
$ aws ecs describe-tasks --cluster ecs-cluster-dev-seneca-14 --tasks f48577cb-7812-4b8c-8945-9c3a99886fdf

------------------------------------------
stop a Task
------------------------------------------
# we may need to stop existing Tasks before starting a new Service in the same Cluster
$ aws ecs stop-task --cluster ecs-cluster-dev-seneca-14 --task <task_id or arn>

------------------------------------------
write task definition json
------------------------------------------
# to get a template for task definition:
$ aws ecs run-task --generate-cli-skeleton


================================================
To start a new Service using service definition
================================================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/task_service_definitions

------------------------------------------
create a Service (run a new Service)
------------------------------------------
# first you need to
# register Task Definition (see above)
# create a load balancer (see alb_scripts)

# finally, create the service:
$ aws ecs create-service --service-name ecs-service-seneca-14 --cli-input-json file://./ecs_service_definition.json

------------------------------------------
To update an existing Service
------------------------------------------
# we need to update desired-count to 0 before deleting a Service
$ aws ecs update-service --cluster ecs-cluster-dev-seneca-14 --service <service_name> --desired-count 0

------------------------------------------
write Service definition json
------------------------------------------
# to get a template for service definition:
$ aws ecs create-service --generate-cli-skeleton


#####################################
Explanation of files and scripts
#####################################

=================
ecs-agent
=================
ecs-agent is the service orchestrator for ECS. It monitors the performance
of all containers in a ECS cluster, and reports to the ECS orchestrator.


=================
registrator
=================
In most situations, we have one ecs-agent per EC2 instance.
The ECS orchestrator can associate one ecs-agent with one container.
But, if we have more than container running on each EC2 instance,
the ECS orchestrator will need additional help keeping track of
multiple containers on each EC2 instance. That is where registrator
comes to help.

Registrator is an agent that keeps track of containers on an EC2 instance.
It registers new containers that come onboard, and identifies
which containers have stopped or failed. It reports that info back to the
ECS orchestrator, so that ECS can keep all containers up and running
at all times.


====================
Task Definition
====================
#TODO



====================
Service Definition
====================
#TODO



#####################################
Resources
#####################################
Installing and running ecs-agent:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html

Writing task definitions:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html

Task scheduling:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html

ECS Services:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html

ECS troubleshooting:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html

ECR troubleshooting:
https://docs.aws.amazon.com/AmazonECR/latest/userguide/common-errors.html
