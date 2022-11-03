#!/usr/bin/env python

"""
Updates stack parameters. Currently the following parameters are supported:
- KeyPairName
- AmiId
- Env
- OwnerContact

######
USAGE
######
$ python 03_update_stack.py --s ecs-stack-dev-seneca-12

AWS CLI equivalent:
#TODO


#######
Inputs
#######
- AWS region
- AWS profile
- AWS stack name
- new AMI ID


########
Outputs
########
Updates the stack using boto's client.update_stack() function.
If successful, prints boto's response to stdout.
Otherwise, raises an error.

"""

import boto3
import argparse
import logging
import yaml
from botocore.exceptions import ClientError
from aurelius.iam.sts_tokens.boto_session_handler import BotoSessionHandler

log_level = getattr(logging, 'INFO')
logging.basicConfig(level=log_level)
log = logging.getLogger()

aws_profile = ""

#######################################
def read_yaml_from_file(yaml_file):
    # Read YAML file and return Dictionary
    with open(yaml_file, 'r') as yf:
        return yaml.load(yf)
#######################################

#######################################
def process_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-p', '--profile',
        dest='profile',
        action='store',
        required=False,
        help='AWS instance profile (IAM Role)'
    )
    parser.add_argument(
        '-a', '--ami-id',
        dest='ami_id',
        action='store',
        required=True,
        help='We use only one AMI_ID in the CFT, so mapping between (dev,qa,prod) and regions is maintained outside'
    )
    parser.add_argument(
        '-r', '--region',
        dest='aws_region',
        action='store',
        required=False,
        help='AWS Region. Defaults to us-west-2'
    )
    parser.add_argument(
        '-s', '--stack-name',
        dest='stack_name',
        action='store',
        required=True,
        help='Name of ECS stack to update'
    )

    # Process arguments
    all_args = parser.parse_args()

    return all_args
#######################################

#######################################
def update_cluster():

    template_text = open(template_path, 'r').read()
    boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
    cfn_client = boto_handler.get_client()

    try:
        response = cfn_client.update_stack(
            StackName=args.stack_name,
            TemplateBody=template_text,
            Parameters=[
                {
                    'ParameterKey': 'ECSClusterName',
                    'UsePreviousValue': True
                },
                {
                    'ParameterKey': 'KeyPairName',
                    'UsePreviousValue': True
                },
                {
                    'ParameterKey': 'AmiId',
                    'ParameterValue': args.ami_id,
                    'UsePreviousValue': False
                },
                {
                    'ParameterKey': 'Env',
                    'UsePreviousValue': True
                },
                {
                    'ParameterKey': 'OwnerContact',
                    'UsePreviousValue': True
                },
            ],
            Capabilities=[
                'CAPABILITY_IAM',
            ],
            Tags=[
                {
                    'Key': 'AutobahnTag',
                    'Value': args.stack_name
                }
            ]
        )
        print str(response)
    except ClientError as e:
        handle_client_error(e)
#######################################

#######################################
def handle_client_error(e):
    if e.response['Error']:
        raise e.response['Error']
    else:
        raise "Unexpected error: %s" % e.message
#######################################


#######################################
if __name__ == "__main__":
    args = process_arguments()
    template_path = "../ecs-cluster-cft-amznlnx.json"
    update_cluster()
