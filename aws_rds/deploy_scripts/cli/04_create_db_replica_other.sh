#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1


#######################################
### Replication within the same region (non-Aurora)
# Aurora Replicas are independent endpoints in an Aurora DB cluster, best used for scaling read operations and increasing availability.
# https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance-read-replica.html
aws rds create-db-instance-read-replica
    --db-instance-identifier <value> \
    --source-db-instance-identifier <db_instance_id> \
    --db-instance-class <db_instance_class> \
    --availability-zone <az> \
    --db-cluster-identifier <db_cluster_id>


#######################################
### Replication cross-region
### (Step 1) Create a new db cluster
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Replication.CrossRegion.html
# Call the AWS CLI create-db-cluster command in the destination region.
# Specify the ARN of the source DB cluster in the --replication-source-identifier option.
# For cross-region replication where the source DB cluster is encrypted,
# you must also specify both the --source-region, and the --kms-key-id options.
# You can only have one cross-region Read Replica DB cluster for each source DB cluster.
aws rds create-db-cluster \
  --db-cluster-identifier sample-replica-cluster \
  --engine aurora \
  --replication-source-identifier arn:aws:rds:us-west-2:123456789012:cluster:sample-master-cluster \
  --kms-key-id my-us-east-1-key \
  --source-region us-west-2


### (Step 2) Check that the DB cluster has become available.
aws rds describe-db-clusters --db-cluster-identifier sample-replica-cluster


### (Step 3) create the primary instance for the DB cluster so that replication can begin
aws rds create-db-instance \
  --db-cluster-identifier sample-replica-cluster \
  --db-instance-class db.r3.large \
  --db-instance-identifier sample-replica-instance \
  --engine aurora


### (Step 4) see if the DB instance is available by calling the AWS CLI describe-db-instances command
