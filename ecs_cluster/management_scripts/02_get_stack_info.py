#!/usr/bin/env python

"""
A script to get desired info for a stack or cluster.

#######
Usage
#######
# by cluster name:
$ python 02_get_stack_info.py -m get_stack_status -c ecs-cluster-dev-seneca-11 -r 'us-west-2'

# by stack name:
$ python 02_get_stack_info.py -m get_stack_status -s ecs-stack-dev-seneca-11 -r 'us-west-2'

AWS CLI equivalent:
#TODO


#######
Inputs
#######
Specify AWS region, profile, stack or cluster name, parameter of interest,
and what info you want from AWS which can be one of the following:
- 'get_stack_status',
- 'get_full_stack_details',
- 'get_instance_ips',
- 'get_param',
- 'get_stack_name_from_cluster_name'


########
Outputs
########
Depending on the call_method specified by the user, one of the following:
- stack resources
- stack status
- stack IPs
- a specific parameter in the stack
- stack name (CloudFormation) from cluster name (ECS)


"""

import logging
import argparse
import botocore
log_level = getattr(logging, 'INFO')
logging.basicConfig(level=log_level)
log = logging.getLogger()

from aurelius.iam.sts_tokens.boto_session_handler import BotoSessionHandler


#######################################
def process_arguments():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--method', '-m',
        dest='call_method',
        action='store',
        default=None,
        required=True,
        choices=['get_stack_status', 'get_full_stack_details', 'get_instance_ips', 'get_param',
                 'get_stack_name_from_cluster_name'],
        help='[ get_stack_status, get_full_stack_details, get_instance_ips, get_param,'
             'get_stack_name_from_cluster_name ]'
    )
    parser.add_argument(
        '--region', '-r',
        dest='aws_region',
        action='store',
        default=False,
        required=True,
        help=''
    )
    parser.add_argument(
        '--profile', '-p',
        dest='aws_profile',
        action='store',
        default="",
        required=False,
        help=''
    )
    parser.add_argument(
        '--param',
        dest='get_param',
        action='store',
        default=False,
        required=False,
        help='Enter the param to get from the stack details'
    )

    # we can either use stack name or the cluster name, but not both
    arg_group = parser.add_mutually_exclusive_group()
    arg_group.add_argument(
        '--stack-name', '-s',
        dest='aws_stack_name',
        action='store',
        default=False,
    )
    arg_group.add_argument(
        '--cluster-name', '-c',
        dest='aws_cluster_name',
        action='store',
        default=False
    )

    # Process arguments
    all_args = parser.parse_args()
    return all_args
#######################################

#######################################
def get_param():

    if args.get_param is False:
        print "Must include --param <key to search for>"
        return False

    try:
        boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
        cfn_client = boto_handler.get_client()
        response = cfn_client.describe_stacks(StackName=args.aws_stack_name)

        for param in response['Stacks'][0]['Parameters']:
            if param['ParameterKey'] == args.get_param:
                return param['ParameterValue']

        return "Parameter does not exist in this Stack"

    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "ValidationError":
            return e.response['Error']['Message']

    return response
#######################################

#######################################
def get_full_stack_details():

    try:
        boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
        cfn_client = boto_handler.get_client()
        response = cfn_client.describe_stack_resources(StackName=args.aws_stack_name)

        return response

    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "ValidationError":
            return e.response['Error']['Message']
#######################################

#######################################
def get_stack_status():

    try:
        boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
        cfn_client = boto_handler.get_client()
        response = cfn_client.describe_stacks(StackName=args.aws_stack_name)
        for details in response['Stacks']:
            stackstatus = details['StackStatus']

        return stackstatus

    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "ValidationError":
            return e.response['Error']['Message']
#######################################

#######################################
def get_instance_ips():
    aws_asg_name = get_asg_name_from_stack_name()
    instances = get_instances_from_asg_name(aws_asg_name)

    if len(instances) > 0:
        instance_ips = get_instances_ips_from_instances(instances)

    return instance_ips
#######################################

#######################################
def get_stack_name_from_cluster_name():
    boto_handler = BotoSessionHandler(aws_service='ecs', aws_region='us-west-2')
    ecs_client = boto_handler.get_client()
    response = ecs_client.list_container_instances(cluster=args.aws_cluster_name)

    if len(response['containerInstanceArns']) == 0:
        log.error("Cluster {} not found.".format(args.aws_cluster_name))

    container_instance = response['containerInstanceArns'][0]

    response = ecs_client.describe_container_instances(cluster=args.aws_cluster_name,
                                                       containerInstances=[container_instance])
    ec2_instance_id = response['containerInstances'][0]['ec2InstanceId']

    stack_name = get_stack_name_from_ec2_instance(ec2_instance_id)

    return stack_name
#######################################

#######################################
def get_stack_name_from_ec2_instance(ec2_instance_id):
    boto_handler = BotoSessionHandler(aws_service='ec2', aws_region='us-west-2')
    ec2_client = boto_handler.get_client()
    instance_details = ec2_client.describe_instances(InstanceIds=[ec2_instance_id])
    for reservation in instance_details['Reservations']:
        for instance in reservation['Instances']:
            for tag in instance['Tags']:
                if tag['Key'] == "aws:cloudformation:stack-name":
                    return tag['Value']

    return False
#######################################

#######################################
def get_asg_name_from_stack_name():
    boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
    cfn_client = boto_handler.get_client()
    response = cfn_client.describe_stack_resources(StackName=args.aws_stack_name)
    for resource in response['StackResources']:
        if resource['ResourceType'] == "AWS::AutoScaling::AutoScalingGroup":
            return resource['PhysicalResourceId']

    return False
#######################################

#######################################
def get_instances_from_asg_name(aws_asg_name):
    instances = []
    boto_handler = BotoSessionHandler(aws_service='autoscaling', aws_region='us-west-2')
    asg_client = boto_handler.get_client()
    asg_details = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[aws_asg_name])
    for asg in asg_details['AutoScalingGroups']:
        for instance in asg['Instances']:
            instances.append(instance['InstanceId'])

    return instances
#######################################

#######################################
def get_instances_ips_from_instances(instances):
    instance_ips = []
    boto_handler = BotoSessionHandler(aws_service='ec2', aws_region='us-west-2')
    ec2_client = boto_handler.get_client()
    instance_details = ec2_client.describe_instances(InstanceIds=instances)
    for reservation in instance_details['Reservations']:
        for instance in reservation['Instances']:
            instance_ips.append(instance['PrivateIpAddress'])

    return instance_ips
#######################################

#######################################
def main():
    if args.aws_stack_name is False:
        args.aws_stack_name = get_stack_name_from_cluster_name()

    try:
        result = eval(args.call_method)()

    except NameError:
        print "Action does not exist"

    print result
#######################################

#######################################
if __name__ == "__main__":
    args = process_arguments()
    main()
