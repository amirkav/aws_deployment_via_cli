#!/usr/bin/env python

"""
Updates runtime scripts for provisioning and
pushes new runtime scripts to S3 provisioning bucket.

#######
Inputs
#######
- AWS region
- environment: dev, qa, prod
- profile
- folder_suffix


########
Outputs
########
Uploads provisioning scripts to S3.
Prints the settings to stdout.


########
Usage
########
#TODO

AWS CLI equivalent:
#TODO
"""

import argparse
import yaml
import os
import tarfile
import boto3
import errno
import logging

log_level = getattr(logging, 'INFO')
logging.basicConfig(level=log_level)
log = logging.getLogger()

#######################################
def process_arguments():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--environment', '-e',
        dest='environment',
        action='store',
        default=None,
        required=True,
        choices=['dev', 'qa', 'prod'],
        help='[ dev, qa, prod ]'
    )
    parser.add_argument(
        '--folder-suffix', '-f',
        dest='folder_suffix',
        action='store',
        default='default',
        required=False,
        help=''
    )
    parser.add_argument(
        '--profile', '-p',
        dest='aws_profile',
        action='store',
        default='',
        required=False,
        help=''
    )
    parser.add_argument(
        '-r', '--region',
        dest='region',
        action='store',
        required=True,
        help='AWS Region (us-east-1, us-west-2)'
    )

    # Process arguments
    all_args = parser.parse_args()
    return all_args
#######################################

#######################################
def main():

    if args.environment == "prod":
        provisioning_bucket = settings['prod_provisioning_bucket']
    else:
        provisioning_bucket = settings['non_prod_provisioning_bucket']

    provisioning_folder = "{0}/{1}/{2}-{3}".format(args.environment, args.region, settings['ecs_service_name'],
                                                   args.folder_suffix)

    script_path = os.path.dirname(os.path.abspath(__file__)) + "/"
    build_dir = script_path + "../build"
    # Note: as google says, in Python >3.2 you can create the whole path without try even if it exists
    try:
        os.makedirs(build_dir)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(build_dir):
            logging.debug('Directory exists: %s', build_dir)
            pass
        else:
            raise

    with tarfile.open(script_path + "../build/runtime-scripts.tar.gz", "w:gz") as tar:
        tar.add(script_path + "../runtime-scripts", arcname=".")

    # s3_path = "s3://{0}/{1}/".format(provisioning_bucket, provisioning_folder)

    client = boto3.client('cloudformation')
    client.upload_file(script_path + "../build/runtime-scripts.tar.gz", "nsb-"+args.region+"-"+provisioning_bucket,
                       provisioning_folder + "/runtime-scripts.tar.gz", ExtraArgs={'ServerSideEncryption': "AES256"})

    print settings


#######################################
def setup():
    # if args.aws_profile == '':
    #     client = boto3.client('s3', region_name=args.region)
    # else:
    #     session = boto3.Session(profile_name=args.aws_profile)
    #     client = session.client('s3', region_name=args.region)
    aws_profile = args.profile
    if aws_profile == "":
        boto3.setup_default_session(region_name=args.aws_region)
    else:
        boto3.setup_default_session(profile_name=aws_profile, region_name=args.aws_region)

    log.info('boto3 session initiated.')

    return True


#######################################
def _parse_yaml(filename):

    with open(filename, "r") as settings_file:
        try:
            parsed_data = yaml.load(settings_file)
        except yaml.YAMLError as error:
            print error
    return parsed_data


#######################################
if __name__ == "__main__":
    args = process_arguments()
    script_dir = os.path.dirname(os.path.realpath(__file__))
    settings = _parse_yaml(script_dir + "/cluster-settings.yml")

    main()
