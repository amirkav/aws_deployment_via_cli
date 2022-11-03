

#################################################
CloudWatch Logging Agent Configs
#################################################


=================================================
awslogs.conf file structure
=================================================
The awslogs.conf file has a separate section for each log that is sent to CloudWatch.
- [header]: each section has a header that is used to tell awslogs that a new log file and stream is being introduced.
- file: log file on local file storage
- log_group_name: CloudWatch log group name. Use the application name for this value.
- log_stream_name: CloudWatch log stream name. Use the physical device (cluster / instance) for this value.

We also have a separate section for agent state file. Just use the following template:
[general]
state_file = /var/lib/awslogs/agent-state


=================================================
To upload revised awslogs agent configs to S3
=================================================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/logging_configs
$ aws s3 cp ./awslogs.conf s3://bbs-seneca-conf-pub/awslogs.conf --sse="AES256"
$ aws s3 cp ./awslogs_container.conf s3://bbs-seneca-conf-pub/awslogs_container.conf --sse="AES256"
$ aws s3 cp ./supervisord.conf s3://bbs-seneca-conf-pub/supervisord.conf --sse="AES256"


=================================================
Sample awslogs.conf files
=================================================

--------------------------------
awslogs.conf
--------------------------------
CloudWatch logs config for the main container.
If we use the logging container (see below on how to run awslogs from within a separate container),
we can mount a volume from the main container into the logging container,
and then move the awslogs.conf instructions from here to the
logging container awslogs.conf file.


--------------------------------
awslogs_container.conf
--------------------------------
CloudWatch logs config file for the logging container.
We are currently using the logging container to just log
the application logs. So, it only has instructions for
application log. If we mount container instance logs into
the logging container, we will add those log locations to
this config file too.




########################################################
Installing CloudWatch Logging Agent Using yum
########################################################
This method will run the awslogs agent on the same instance as we run our application.
This is the normal and mostly-used method.

See "setup_cloudwatch_loging.sh" script and the UserData section of the CFT.
$ sudo yum install -y awslogs
# then update the awslogs.conf file
$ sudo /bin/systemctl start awslogsd
$ sudo /bin/systemctl enable awslogsd.service



##########################################################
Running CloudWAtch Logging Agent From Dedicated Container
##########################################################
This method runs the CloudWatch Logging Agent is a separate container,
and reads the logs from our instances and sends them to CloudWatch.
The benefit of this method is that we can have a single, centralized
logging container that does not interfere with the worker instances.


==================
Pre-reqs
==================

Install Git and Docker.
$ sudo yum update -y && sudo yum -y install git docker

Make sure that the Docker service is running:
$ sudo service docker start

Clone the GitHub repository containing the files you need:
$ cd /opt
$ git clone https://github.com/awslabs/ecs-cloudwatch-logs.git
$ cd ecs-cloudwatch-logs


==================
Installation
==================
0) Create a new repository in your ECR, and call it "cloudwatchlogs"

1) Retrieve the docker login command that you can use to authenticate your Docker client to your registry.
$ aws ecr get-login --no-include-email --region us-west-2


2) Log into ECR
$ export ecr_login=$(sudo aws ecr get-login --region us-west-2 --registry-ids 474602133305 --no-include-email)
$ sudo ${ecr_login}


3) Build your Docker image using the following command.
You can skip this step if your image is already built:
$ cd ${GITS_DIR}/../
$ sudo docker build -t cloudwatchlogs -f Dockerfile .


4) After the build completes, tag your image so you can push the image to this repository:
$ sudo docker tag cloudwatchlogs:latest 474602133305.dkr.ecr.us-west-2.amazonaws.com/cloudwatchlogs:latest


5) Run the following command to push this image to your newly created AWS repository:
$ sudo docker push 474602133305.dkr.ecr.us-west-2.amazonaws.com/cloudwatchlogs:latest


==================
USAGE
==================
$ cd ${GITS_DIR}/aurelius/ecs-cluster/logging_configs
$ python ./awslogs-agent-setup.py -n -r us-west-2 -c ./awslogs_container.conf



#############
DEBUGGING
#############

==========================
awslogs log file
==========================
/var/log/awslogs.log


==========================
Location of config file
==========================
The yum command saves the config file to the following location:
/etc/awslogs/awslogs.conf

But, the install script awslogs-agent-setup.py saves the config file to:
/var/awslogs/awslogs.conf


======================================================
ISSUE: "unable to open database file" in awslogs.log
======================================================
If you use the yum command or setup script to install the agent, then you should not have this issue.
The python script does not create the agent_state directory automatically, so we need to do that for it.
$ sudo mkdir -p /var/awslogs/state

https://forums.aws.amazon.com/thread.jspa?threadID=165134


#############
RESOURCES
#############

=======================================
AWS awslogs agent for CloudWatch Logs
=======================================
awslogs getting started:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_GettingStarted.html

Install and run aslogs on a running EC2 instance:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html

Install and run aslogs on a fresh EC2 instance:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/EC2NewInstanceCWL.html

awslogs agent reference:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AgentReference.html

Using CloudWatch logs with container instances:
http://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/using_cloudwatch_logs.html

More tutorials on setting up awslogs agent:
https://cloudacademy.com/blog/centralized-log-management-with-aws-cloudwatch-part-1-of-3/
http://zoltanaltfatter.com/2017/01/13/centralized-logging-with-cloudwatch-logs/
https://www.enovate.co.uk/blog/2015/02/07/how-to-set-up-and-configure-aws-cloudwatch-logs

Centralized Log Management with CloudWatch
https://cloudacademy.com/blog/centralized-log-management-with-aws-cloudwatch-part-1-of-3/
http://zoltanaltfatter.com/2017/01/13/centralized-logging-with-cloudwatch-logs/
https://www.enovate.co.uk/blog/2015/02/07/how-to-set-up-and-configure-aws-cloudwatch-logs


==================
rsyslog resources
==================
Overview of logging in Linux and how to configure it:
https://www.digitalocean.com/community/tutorials/how-to-view-and-configure-linux-logs-on-ubuntu-and-centos

Next steps: How to centralize logging using rsyslog, logstash, elastic search
https://www.digitalocean.com/community/tutorials/how-to-centralize-logs-with-rsyslog-logstash-and-elasticsearch-on-ubuntu-14-04

RHEL rsyslog reference
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/s1-basic_configuration_of_rsyslog


