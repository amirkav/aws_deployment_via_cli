#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.CreateInstance.html

export db_cluster_name=rds-db-cluster-seneca-05
export db_instance_name=rds-db-instance-seneca-05


#######################################
### create a db cluster
#aws rds create-db-cluster --db-cluster-identifier sample-cluster \
#    --engine aurora-mysql \
#    --engine-version 5.7.12 \
#    --master-username user-name \
#    --master-user-password password \
#    --db-subnet-group-name mysubnetgroup \
#    --vpc-security-group-ids sg-c7e5b0d2


dbcluster_reponse=$(aws rds create-db-cluster --db-cluster-identifier ${db_cluster_name} \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/create_db_cluster.json)

dbcluster_reader_endpoint=$(echo $dbcluster_reponse | jq '.DBCluster.ReaderEndpoint' | sed -e 's/"$//' -e 's/^"//')
dbcluster_endpoint=$(echo $dbcluster_reponse | jq '.DBCluster.Endpoint' | sed -e 's/"$//' -e 's/^"//')
dbcluster_ResourceId=$(echo $dbcluster_reponse | jq '.DBCluster.DbClusterResourceId' | sed -e 's/"$//' -e 's/^"//')
dbcluster_arn=$(echo $dbcluster_reponse | jq '.DBCluster.DBClusterArn' | sed -e 's/"$//' -e 's/^"//')


#######################################
### create the primary instance for your DB cluster
#aws rds create-db-instance --db-instance-identifier sample-instance \
#     --db-cluster-identifier sample-cluster \
#     --engine aurora-mysql \
#     --db-instance-class db.r4.large \
#     --storage-encrypted true

# NOTE: in the DB Instance JSON file, you cannot set "MultiAZ: true" for Aurora engines.
# Aurora will by default spread the db volume across three different AZs to increase availability.
# So you dont need to create MultiAZ for high availability on top of that.
# But, if you want fast read response AND fast recovery when a failover occurs,
# you can create a Read Replica in a different AZ after you create your primary Aurora db instance.
# For details, read: https://www.reddit.com/r/aws/comments/61u9ah/is_rds_aurora_multiaz_by_default/
dbcluster_reponse=$(aws rds create-db-instance --db-instance-identifier ${db_instance_name}-primary-us-west-2a \
    --availability-zone us-west-2a \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/create_db_instance.json)




#######################################
### describe the db cluster and instance that you just created
aws rds describe-db-clusters --region us-west-2
aws rds describe-db-instances --db-instance-identifier rds-instance-seneca-1

# describe instance name and id
aws rds describe-db-instances \
    --query "DBInstances[*].[DBInstanceIdentifier,DbiResourceId]"


#######################################
### add tags to the resource
# http://docs.aws.amazon.com/cli/latest/reference/rds/add-tags-to-resource.html
aws rds add-tags-to-resource \
    --resource-name <value> \
    --tags <value>


### list tags for a resource
# https://docs.aws.amazon.com/cli/latest/reference/rds/list-tags-for-resource.html
aws rds list-tags-for-resource
    --resource-name <value> \
    [--filters <value>]


### remove tags from a resource
# https://docs.aws.amazon.com/cli/latest/reference/rds/remove-tags-from-resource.html
aws rds remove-tags-from-resource
    --resource-name <value> \
    --tag-keys <value>
