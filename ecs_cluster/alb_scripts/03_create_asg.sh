#!/bin/bash
exec > >(tee -a /var/log/alb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

# NOTE: In this method, instead of directly registering instances,
# we register an Autoscaling Group with the Target Group and
# have the ASG register and de-register new instances with the TG.

cd ${GITS_DIR}/aurelius/ecs-cluster/alb_scripts

###################
### Create ASG launch configuration
# https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-config.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-launchconfig.html
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-launch-configuration.html

# If you need a template for the json file, use the following command:
aws autoscaling create-launch-configuration --generate-cli-skeleton

# After creating and saving the launch config json file:
aws autoscaling create-launch-configuration --launch-configuration-name ecs-asg-launch-config-${ENV}-${STACK_SUFFIX} --cli-input-json file://asg-launch-config.json


###################
### Create the ASG and attach the ASG to Target Group
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/quickref-autoscaling.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-policy.html
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html

# Note that Target Group is attached to VPC, not Subnet.
# And, we dont have a Subnet identifier in ASG Launch Configuration.
# So, the ASG still does not know which Subnet to create the targets in,
# which is why we have to supply the list of subnets in the command below.

aws autoscaling create-auto-scaling-group --auto-scaling-group-name ecs-asg-${ENV}-${STACK_SUFFIX} --launch-configuration-name ecs-asg-launch-config-${ENV}-${STACK_SUFFIX} --min-size 3 --max-size 3 --target-group-arns ${tg_arn} --vpc-zone-identifier ${SUBNET_1},${SUBNET_2}


###################
### To detach or attach the ASG to another Target Group
# http://docs.aws.amazon.com/cli/latest/reference/autoscaling/attach-load-balancer-target-groups.html
# $ aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name my-asg --target-group-arns my-targetgroup-arn

# http://docs.aws.amazon.com/cli/latest/reference/autoscaling/detach-load-balancer-target-groups.html
# $ aws autoscaling detach-load-balancer-target-groups --auto-scaling-group-name my-asg --target-group-arns my-targetgroup-arn
