#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.html
# http://docs.aws.amazon.com/cli/latest/reference/rds/create-event-subscription.html
# Note: If SourceIds are supplied, SourceType must also be provided.
aws rds create-event-subscription --subscription-name rds-events-3 \
    --sns-topic-arn arn:aws:sns:us-west-2:474602133305:rds-events \
    --source-type db-cluster \
    --source-ids ${db_cluster_name}\
    --enabled


# make sure it is created
aws rds describe-event-subscriptions


# modify event subscription
# Note: If SourceIds are supplied, SourceType must also be provided. So, if
# you want to add source id in the next command, you should add source type beforehand.
aws rds modify-event-subscription \
    --subscription-name rds-events \
    --source-type db-cluster


# add source identifier to the events subscription
# https://docs.aws.amazon.com/cli/latest/reference/rds/add-source-identifier-to-subscription.html
aws rds add-source-identifier-to-subscription \
    --subscription-name rds-events \
    --source-identifier ${db_cluster_name}


# delete an RDS events notification
aws rds delete-event-subscription --subscription-name rds-events


# to view all rds events for the past 7 days: 7*24*60
aws rds describe-events --duration 10080
