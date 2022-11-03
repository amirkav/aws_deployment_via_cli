#!/bin/bash
exec > >(tee -a /var/log/alb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

$ cd ${GITS_DIR}/aurelius/ecs-cluster/alb_scripts

###################
### Specify parameters and variables
export STACK_PREFIX=ecs-stack
export STACK_SUFFIX=seneca-4
export ENV=dev
export SUBNET_1=subnet-02fa0570d0c5dd119
export SUBNET_2=subnet-f3e6f595
export SG_1=sg-2a252856
export SG_2=sg-35f5f949
export VPC_ID=vpc-d4c914ad
export ec2_id_1=i-0158d46cdeb0cf1e4
export ec2_id_2=i-0b1d0638c0122da25
export ec2_id_3=i-0dac5e37bb0780e97


###################
### Create a load balancer. You must specify two subnets that are not from the same Availability Zone.
alb_response=$(aws elbv2 create-load-balancer --name ecs-alb-${ENV}-${STACK_SUFFIX} --subnets ${SUBNET_1} ${SUBNET_2} --security-groups ${SG_1} ${SG_2})
alb_arn=$(echo $alb_response | jq '.LoadBalancers[0].LoadBalancerArn' | sed -e 's/"$//' -e 's/^"//')
