#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html

# NOTE: RDS Aurora supports both Cluster Parameter Groups and Instance Parameter Groups.
# Cluster and Instance Param Groups do not overlap, so we need to assign values to both.

export db_cluster_pg_name=bbs-db-cluster-paramgroup-02
export db_instance_pg_name=bbs-db-instance-paramgroup-02

#######################################
### List param groups
# http://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-parameter-groups.html
aws rds describe-db-cluster-parameter-groups
aws rds describe-db-parameter-groups


###################
### List param group values
# http://docs.aws.amazon.com/cli/latest/reference/rds/describe-db-parameters.html
aws rds describe-db-cluster-parameters --db-cluster-parameter-group-name ${db_cluster_pg_name}
aws rds describe-db-parameters --db-parameter-group-name ${db_instance_pg_name}


#######################################
### Copy param group
# http://docs.aws.amazon.com/cli/latest/reference/rds/copy-db-parameter-group.html
aws rds copy-db-cluster-parameter-group \
    --source-db-parameter-group-identifier ${db_cluster_pg_name} \
    --target-db-parameter-group-identifier ${db_cluster_pg_name}-copy \
    --target-db-parameter-group-description "db cluster param group copy"


#######################################
### Create a new (empty) param group
# Note: we cannot create and populate the param group in one command.
# Instead, we need to first create the param group, and then populate it.
aws rds create-db-cluster-parameter-group \
    --db-cluster-parameter-group-name ${db_cluster_pg_name} \
    --db-parameter-group-family aurora-mysql5.7 \
    --description "DB Cluster Parameter Group for BBS Aurora database clusters"

aws rds create-db-parameter-group \
    --db-parameter-group-name ${db_instance_pg_name} \
    --db-parameter-group-family aurora-mysql5.7 \
    --description "DB Instance Parameter Group for BBS Aurora database instances"


###################
### Modify a param group to specify property values
# aws rds modify-db-cluster-parameter-group --generate-cli-skeleton
# https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-cluster-parameter-group.html
aws rds modify-db-cluster-parameter-group \
    --db-cluster-parameter-group-name ${db_cluster_pg_name} \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/mysql_pg_properties.json

# https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-parameter-group.html
# aws rds modify-db-parameter-group --generate-cli-skeleton
aws rds modify-db-parameter-group \
    --db-parameter-group-name ${db_instance_pg_name} \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/db_instance_pg_properties.json


#######################################
### Apply the parameter group to a db cluster or instance
# https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-cluster.html
aws rds modify-db-cluster
    --db-cluster-identifier <value>\
    --db-cluster-parameter-group-name ${db_cluster_pg_name}

# https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-instance.html
aws rds modify-db-instance
    --db-instance-identifier <value>\
    --db-parameter-group-name ${db_instance_pg_name}

