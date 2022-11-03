#!/bin/bash
exec > >(tee -a /var/log/alb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

# NOTE: In this method, we directly register instances with
# the Target Group, and register the Target Group with the
# Load Balancer using Listeners.


###################
### Create a target group, specifying the same VPC that you used for your EC2 instances.
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/create-target-group.html
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/add-tags.html
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/register-targets.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-elasticloadbalancingv2-targetgroup.html

tg_response=$(aws elbv2 create-target-group --name ecs-tg-${ENV}-${STACK_SUFFIX} --protocol HTTP --port 80 --vpc-id ${VPC_ID})
tg_arn=$(echo $tg_response | jq '.TargetGroups[0].TargetGroupArn' | sed -e 's/"$//' -e 's/^"//')


###################
### (optional) Add tags to the target group
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/add-tags.html
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/remove-tags.html


###################
### (deprecated) directly register existing EC2 instances with your target group
# In our new deployment model, we attach an ASG to the TG to automatically register / de-register instances
# $ instance_response=$(aws elbv2 register-targets --target-group-arn ${tg_id} --targets Id=${ec2_id_1} Id=${ec2_id_2} Id=${ec2_id_3})
