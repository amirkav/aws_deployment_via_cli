#!/usr/bin/env python
"""
AWS class that:
 - supports connections with and without profile
 - deletes stacks and associated S3 buckets


######
USAGE
######
$ python 05_delete_stack.py -s ecs-stack-dev-seneca-12 -r 'us-west-2'

AWS CLI equivalent:
#TODO
"""

import argparse
import logging
import boto3
from botocore.exceptions import ClientError
from aurelius.iam.sts_tokens.boto_session_handler import BotoSessionHandler

log_level = getattr(logging, 'INFO')
logging.basicConfig(level=log_level)
log = logging.getLogger()

aws_profile = ""


#######################################
def process_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-s', '--stack-name',
        dest='stack_name',
        action='store',
        required=True,
        help='AWS Stack name'
    )
    parser.add_argument(
        '-r', '--region',
        dest='region',
        action='store',
        required=True,
        help='AWS Region (us-east-1, us-west-2)'
    )
    parser.add_argument(
        '-p', '--profile',
        dest='profile',
        action='store',
        help='AWS instance Profile (IAM Role)'
    )
    all_args = parser.parse_args()
    return all_args
#######################################

#######################################
def delete_stack(stack_name):
    boto_handler = BotoSessionHandler(aws_service='cloudformation', aws_region='us-west-2')
    cfn_client = boto_handler.get_client()

    log.info("Deleting: {}".format(stack_name))
    try:
        r = cfn_client.delete_stack(StackName=stack_name)
        print str(r)

    except ClientError as e:
        handle_client_error(e)
#######################################

#######################################
def handle_client_error(e):
    if e.response['Error']:
        raise e
    else:
        raise "Unexpected error: %s" % e.message
#######################################


#######################################
def main():
    args = process_arguments()
    delete_stack(args.stack_name)
#######################################

#######################################
if __name__ == "__main__":
    main()
