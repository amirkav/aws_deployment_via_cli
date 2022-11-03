#!/usr/bin/env python

"""
Python script to create an cloudformation stack in AWS
based on user input arguments, cluster_settings.yml configs,
and ecs-cluster.json template.

########
Usage
########
$ python 01_create_stack.py
        -b ecs-stack  # stack basename
        -u seneca-10  # stack suffix. increment the name
        -c ecs-cluster  # ECS cluster base name
        -e dev  # environment

Example:
$ python 01_create_stack.py -b ecs-stack -c ecs-cluster -e dev -u seneca-11

AWS CLI equivalent:
$ export stack_suffix=seneca-11
$ export env=dev
$ cd ${GITS_DIR}/aurelius/ecs-cluster/templates
$ aws cloudformation create-stack --stack-name ecs-stack-${env}-${stack_suffix} --template-body file://./ecs-cluster-cft-amznlnx.json --parameters ParameterKey=BaseName,ParameterValue=ecs-stack ParameterKey=StackSuffix,ParameterValue=${stack_suffix}
"""

import argparse
import logging
import yaml
import os
import sys

sys.path.append("{}/seneca".format(os.environ['GITS_DIR']))
from aurelius.iam.sts_tokens.boto_session_handler import BotoSessionHandler

log_level = getattr(logging, 'INFO')
logging.basicConfig(level=log_level)
log = logging.getLogger()


#######################################
def process_arguments():
    parser = argparse.ArgumentParser(add_help=False)

    parser.add_argument(
        '-h', '--help',
        dest='help',
        action='help',
        help="""
        Python script to create stack in AWS based on command line arguments and cluster_settings.yml configuration.
        Command line arguments take precedence over cluster_settings.yml configuration.

        Usage: ${script_name} -e environment -b stack_basename -u stack_suffix
               [-c ecs_cluster_basename] [-s ecs_service_name] [-i container-instance-name]
               [-f folder-suffix] [-r aws_region]
        """
    )
    parser.add_argument(
        '-b', '--stack-basename',
        dest='stack_basename',
        action='store',
        required=True,
        default=cluster_settings['stack_basename'],
        help='Specify a base name for the CloudFormation Stack'
    )
    parser.add_argument(
        '-u', '--stack-suffix',
        dest='stack_suffix',
        action='store',
        required=True,
        default=cluster_settings['stack_suffix'],
        help='Stack suffix'
    )
    parser.add_argument(
        '-c', '--ecs-cluster-basename',
        dest='ecs_cluster_basename',
        action='store',
        default=cluster_settings['ecs_cluster_basename'],
        nargs='?', const="",
        help='The name of the ECS cluster to create in the CFN stack'
    )
    parser.add_argument(
        '-e', '--environment',
        dest='environment',
        action='store',
        choices=['dev', 'qa', 'prod'],
        required=True,
        default='dev',
        help='Environment name (e.g. dev,qa,prod)'
    )
    parser.add_argument(
        '-r', '--region',
        dest='aws_region',
        action='store',
        default=cluster_settings['aws_region'],
        nargs='?', const=cluster_settings['aws_region'],
        help='AWS region used for creating stack (e.g. us-east-1,us-west-2) '
    )

    all_args = parser.parse_args()

    return all_args


#######################################
def create_cluster():

    cluster_settings = read_yaml_from_file("{GITS_DIR}/aurelius/ecs-cluster/management_scripts/cluster_settings.yml".format(
        GITS_DIR=os.environ['GITS_DIR']))
    template_text = open('{GITS_DIR}/aurelius/ecs-cluster/templates/{t_name}'.format(
        GITS_DIR=os.environ['GITS_DIR'],
        t_name=cluster_settings['template_name']), 'r').read()

    ami_id = cluster_settings['environments'][args.environment][args.aws_region]['ami_id']
    keypair_name = cluster_settings['environments'][args.environment][args.aws_region]['keypair_name']

    boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
    cfn_client = boto_handler.get_client()

    try:
        response = cfn_client.create_stack(
            StackName=create_stack_name(),
            TemplateBody=template_text,
            Parameters=[
                {
                    'ParameterKey': 'BaseName',
                    'ParameterValue': args.stack_basename,
                    'UsePreviousValue': True
                },
                {
                    'ParameterKey': 'StackSuffix',
                    'ParameterValue': args.stack_suffix,
                    'UsePreviousValue': True
                },
                {
                    'ParameterKey': 'ECSClusterBaseName',
                    'ParameterValue': args.ecs_cluster_basename,
                    'UsePreviousValue': True
                },

                {
                    'ParameterKey': 'KeyPairName',
                    'ParameterValue': keypair_name,
                    'UsePreviousValue': False
                },
                {
                    'ParameterKey': 'AmiId',
                    'ParameterValue': ami_id,
                    'UsePreviousValue': False
                },
                {
                    'ParameterKey': 'Env',
                    'ParameterValue': args.environment,
                    'UsePreviousValue': False
                },
            ],
            Tags=[
                {
                    'Key': 'Name',
                    'Value': "{name}".format(name=create_stack_name())
                },
            ],
            Capabilities=['CAPABILITY_IAM'],
            OnFailure='ROLLBACK'
        )
    except Exception as e:
        log.error(e)
        exit(1)

    print response


#######################################
def create_stack_name():
    return "{b}-{e}-{u}".format(b=args.stack_basename, e=args.environment, u=args.stack_suffix)


#######################################
def read_yaml_from_file(file_name):
    parsed_yml = None
    with open(file_name, "r") as yf:
        try:
            parsed_yml = yaml.load(yf)
        except yaml.YAMLError as error:
            print error
    return parsed_yml


#######################################
if __name__ == "__main__":
    import os
    import sys

    sys.path.append("{}/seneca".format(os.environ['GITS_DIR']))
    import os
    cluster_settings = read_yaml_from_file("{GITS_DIR}/aurelius/ecs-cluster/management_scripts/cluster_settings.yml".format(
        GITS_DIR=os.environ['GITS_DIR']))

    # Note: for test purposes, we need to either run this from command line (so we can supply arguments)
    # or we need to comment out the next line and have the code read default values from cluster_settings.yml
    args = process_arguments()

    create_cluster()
