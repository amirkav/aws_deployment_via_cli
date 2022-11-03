#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
### (Step 1) Create a SNS Topic
topic_response=$(aws sns create-topic \
    --name ${sns_topic_name})

sns_topic_arn=$(echo $topic_response | jq '.TopicArn' | sed -e 's/"$//' -e 's/^"//')


#######################################
### (Step 2) Subscribe to it (need to confirm from email link)
aws sns subscribe \
    --topic-arn ${sns_topic_arn} \
    --protocol email \
    --notification-endpoint ${notification_endpoint}


#######################################
#######################################
#######################################

#######################################
### (Step 1) Create a SNS Topic for DLQ
topic_response=$(aws sns create-topic \
    --name ${sns_dlq_topic_name})

sns_dlq_topic_arn=$(echo $topic_response | jq '.TopicArn' | sed -e 's/"$//' -e 's/^"//')


#######################################
### (Step 2) Subscribe to it (need to confirm from email link)
aws sns subscribe \
    --topic-arn ${sns_dlq_topic_arn} \
    --protocol email \
    --notification-endpoint ${notification_endpoint}
