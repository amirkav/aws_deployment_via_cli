
###########################
USAGE
###########################
To start a new ECS cluster:
$ export stack_suffix=seneca-11
$ export env=dev
$ cd ${GITS_DIR}/aurelius/ecs-cluster/templates
$ aws cloudformation create-stack --stack-name ecs-stack-${env}-${stack_suffix} --template-body file://./ecs-cluster-cft-amznlnx.json --parameters ParameterKey=BaseName,ParameterValue=ecs-stack ParameterKey=StackSuffix,ParameterValue=${stack_suffix}

To start a new ECS Service in the above cluster:
#TODO


Note: Another way to start a new stack is to
use python scripts in "management_scripts" directory.

Note: a third way to start a new stack is via AWS Console.


################################################
ecs-cluster.json CloudFormation Template
################################################
Creates a ECS cluster, and registers our desired number of EC2 instances into it.

It also starts a registrator agent, which is useful
when we have more than one container per instance.

After this step, we need to define Task Definitions and ECS Services that will
run our application in the ECS cluster that CliudFormation just created.



################################################
Other Methods and Resources for CFT Definition
################################################
Below are examples and resources to create a new CFT for a ASG-ELB-enabled Stack.

=================================================
(a) AWS Guides: using Application Load Balancing
=================================================
(a) Guide on creating a ASG-ELB-enabled Stack in CloudFormation (AWS CFT):
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/example-templates-autoscaling.html
AWS_Example_ASG_ELB.json

This template uses Application Load Balancer, which has the following ARN:
AWS::ElasticLoadBalancingV2::LoadBalancer

It defines three resources:
1. ApplicationLoadBalancer: is a simple definition of the resource, with reference to the subnet
2. ALBListener: is the definition of the listener with reference to the LoadBalancer, TargetGroup, port (80), protocol (HTTP).
3. ALBTargetGroup: definition of the target group with reference to VpcId.

Note that TargetGroup is similar to ASG.


-----------------
Other AWS Guides:
-----------------
- How to define ASG in a template:
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html

- CloudFormation lambda functions to use in templates:
http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html

- ASG guide:
http://docs.aws.amazon.com/autoscaling/latest/userguide/attach-load-balancer-asg.html

- ELB guide:
http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/load-balancer-getting-started.html




################################################
About IAM Roles, Policies, Instance Profile
################################################
- The IAM Role that I use must have the following policy:
AmazonEC2ContainerServiceFullAccess

- I am using the following IAM Role:
BBS-Dev-EC2InECS-Role


================================
Guides for installing ecs-agent
================================
https://github.com/aws/amazon-ecs-agent
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html

