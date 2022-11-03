#!/bin/bash
exec > >(tee -a /tmp/log/deploy_scripts.log) 2>&1

### USAGE
# $ source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/31_create_cw_dash.sh -p meerkat -e dev -d meerkat

# https://aws.amazon.com/blogs/aws/new-api-cloudformation-support-for-amazon-cloudwatch-dashboards/
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cw-dashboard.html
# https://aws.amazon.com/blogs/mt/keeping-cloudwatch-dashboards-up-to-date-using-aws-lambda/
# https://aws.amazon.com/blogs/aws/amazon-cloudwatch-launches-alarms-on-dashboards/
# https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/put-dashboard.html


###################
export dash_name=dinosaur7
export project_name=dinosaur
export env=dev

# Override the above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -p | --project-name )  shift
            export project_name=$1
            ;;
        -e | --env )  shift
            export env=$1
            ;;
        -d | --dash-name )  shift
            export dash_name=$1
            ;;
    esac
    shift
done
###################

###################
### CREATE DASHBOARD BODY JSON
db_clusters_list=$(aws rds describe-db-clusters \
    --region us-west-2 \
    --query 'DBClusters[].DBClusterIdentifier' \
    --output text)

export db_cluster_id=$(echo $db_clusters_list | tr " " "\n" | grep "${project_name}-${env}" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')

#export db_cluster_id=dinosaur-dev-dbcluster-02

#########
list_qs_response=$(aws sqs list-queues --queue-name-prefix ${project_name}-${env})
#TODO: the following line is new. Debug it.
#export q_kws=drive-users-q,drive-users-dlq,drive-files-q,drive-files-dlq,drive-files-rbq,uploader-q,uploader-dlq,uploader-rbq
#IFS=',' read -r -a q_kws_array <<< "$q_kws"
#for q_kw in "${q_kws_array[@]}"
#do
#    echo $q_kw
#    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep ${q_kw})
#    export sqs_q_url_$(echo ${q_kw} | tr "-" "_" )=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
#    export sqs_q_arn_$(echo ${q_kw} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_q_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
#done

export qtypes=uploader,drive-users,drive-files,admin-reports,dir-users,dir-tokens
IFS=',' read -r -a qtypes_array <<< "$qtypes"
list_qs_response=$(aws sqs list-queues --queue-name-prefix ${project_name}-${env})
for qtype in "${qtypes_array[@]}"
do
    echo $qtype
    # get original q details
    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep $qtype-q)
    export sqs_q_url=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
    export sqs_q_url_$(echo ${qtype} | tr "-" "_" )=${sqs_q_url}
#    export sqs_q_arn_$(echo ${qtype} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_q_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
    export sqs_q_name_$(echo ${qtype} | tr "-" "_" )=$(echo $sqs_q_url | tr "/" "\n" | tail -1 | sed -e 's/"$//' -e 's/^"//')
    # get dlq details
    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep $qtype-dlq)
    export sqs_dlq_url=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
    export sqs_dlq_url_$(echo ${qtype} | tr "-" "_" )=${sqs_dlq_url}
#    export sqs_dlq_arn_$(echo ${qtype} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_dlq_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
    export sqs_dlq_name_$(echo ${qtype} | tr "-" "_" )=$(echo $sqs_dlq_url | tr "/" "\n" | tail -1 | sed -e 's/"$//' -e 's/^"//')
    # get rbq details
    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep $qtype-rbq)
    export sqs_rbq_url=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
    export sqs_rbq_url_$(echo ${qtype} | tr "-" "_" )=${sqs_rbq_url}
#    export sqs_rbq_arn_$(echo ${qtype} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_rbq_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
    export sqs_rbq_name_$(echo ${qtype} | tr "-" "_" )=$(echo $sqs_rbq_url | tr "/" "\n" | tail -1 | sed -e 's/"$//' -e 's/^"//')
done

#export sqs_q_name_users=dinosaur-dev-drive-users-q-07
#export sqs_dlq_name_users=dinosaur-dev-drive-users-dlq-07
#export sqs_q_name_files=dinosaur-dev-drive-files-q-07
#export sqs_dlq_name_files=dinosaur-dev-drive-files-dlq-07
#export sqs_q_name_uploader=dinosaur-dev-uploader-q-07
#export sqs_dlq_name_uploader=dinosaur-dev-uploader-dlq-07
#########

lambda_functions_list=$(aws lambda list-functions \
    --region us-west-2 \
    --query 'Functions[].FunctionName' \
    --output text)

export l_kws=drive-scraper-files-orch,drive-scraper-users-orch,drive-scraper-worker,master-uploader
IFS=',' read -r -a l_kws_array <<< "$l_kws"
for l_kw in "${l_kws_array[@]}"
do
    echo $l_kw
    export lambda_list=$(echo $lambda_functions_list | tr " " "\n" | grep "${project_name}-${env}-lambda-${l_kw}")
    export lambda_name_$(echo ${l_kw} | tr "-" "_" )=$(echo $lambda_list | tr " " "\n"  | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
done
#export lambda_name_files=dinosaur-dev-lambda-drive-scraper-files-orch-07
#export lambda_name_users=dinosaur-dev-lambda-drive-scraper-users-orch-07
#export lambda_name_worker=dinosaur-dev-lambda-drive-scraper-worker-07
#export lambda_name_uploader=dinosaur-dev-lambda-master-uploader-07
###################

###################
### CREATE DASHBOARD
# First create the json file that specifies dashboard widgets
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/31_create_cw_dash_body.sh

# If a dashboard with this name already exists, this call modifies that dashboard, replacing its current contents. Otherwise, a new dashboard is created.
aws cloudwatch put-dashboard \
    --dashboard-name ${dash_name} \
    --dashboard-body file://${GITS_DIR}/lucius/deploy_scripts/cli_monitor/31_cw_dash_body.json
###################

###################
### VERIFY
# aws cloudwatch list-dashboards
