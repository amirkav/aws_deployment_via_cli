#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# source ${GITS_DIR}/lucius/deploy_scripts/cli_invoke/30_stop_invocations.sh -p dinosaur -s 04 -env dev -b master-uploader,drive-scraper-users-orch,drive-scraper-files-orch,drive-scraper-worker

export suffix=03
export project_name=dinosaur
export env=dev

#######################################
# Override above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -p | --project-name )  shift
            project_name=$1
            ;;
        -s | --suffix )  shift
            suffix=$1
            ;;
        -e | --env )  shift
            env=$1
            ;;
        -b | --base-names )  shift
            base_names=$1
            ;;
    esac
    shift
done
#######################################

#######################################
### (a) Stop execution of lambda functions
#TODO: or, write similar scripts as SQS and RDS to find Lambda function names automatically and stop them.
stopLambda () {
    source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l $1 -c 0
}

IFS=',' read -r -a base_names_array <<< "$base_names"
for base_name in "${base_names_array[@]}"
do
    stopLambda ${project_name}-${env}-lambda-${base_name}-${suffix}
done
#######################################


#######################################
### (b) Purge SQS queues
list_qs_resp=$(aws sqs list-queues --queue-name-prefix ${project_name})
queue_urls=$(echo ${list_qs_resp} | jq ".QueueUrls[]" --raw-output | sed -e 's/[",]$//' -e 's/^[",]//')

# (i) purge users queue
queue_url_users=$(echo $queue_urls | tr " " "\n" | grep "drive-users-q" | sort -n | tail -1)
echo purging queue ${queue_url_users}
aws sqs purge-queue --queue-url ${queue_url_users}

# (ii) purge files queue
queue_url_files=$(echo $queue_urls | tr " " "\n" | grep "drive-files-q" | sort -n | tail -1)
echo purging queue ${queue_url_files}
aws sqs purge-queue --queue-url ${queue_url_files}

# (iii) purge uploader queue
queue_uploader=$(echo $queue_urls | tr " " "\n" | grep "uploader-q" | sort -n | tail -1)
echo purging queue ${queue_uploader}
aws sqs purge-queue --queue-url ${queue_uploader}
#######################################



#######################################
### (c) Reboot the db instance
db_clusters_resp=$(aws rds describe-db-clusters)
db_cluster_ids=$(echo ${db_clusters_resp} | jq ".DBClusters[].DBClusterIdentifier" --raw-output | sed -e 's/[",]$//' -e 's/^[",]//')
db_cluster_id=$(echo $db_cluster_ids | tr " " "\n" | grep "${project_name}")

desc_db_instance_resp=$(aws rds describe-db-instances \
    --filters Name=db-cluster-id,Values=${db_cluster_id})
db_instance_identifiers=$(echo ${desc_db_instance_resp} | jq ".DBInstances[].DBInstanceIdentifier" --raw-output | tr "\n" "," | sed -e 's/[",]$//' -e 's/^[",]//')
echo $db_instance_identifiers


IFS="," read -r -a db_id_array <<< "$db_instance_identifiers"
for id in "${db_id_array[@]}"
do
    echo $id
    aws rds reboot-db-instance \
        --db-instance-identifier $id
done
#######################################





