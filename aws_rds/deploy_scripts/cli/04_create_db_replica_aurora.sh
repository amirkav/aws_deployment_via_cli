#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1


#######################################
### Create a read replica in a different AZ (for faster read and faster recovery from failover)
# NOTE 1: If using RDS Console to create an instance, it will give you an option "MultiAZ (Cross-region read replica)";
# that option is not the same as the MultiAZ for high availability that we know for other db engines.
# Instead, it automates the process of creating another Read Replica for your Aurora instance.
# The Read Replica will improve read performance, and will drastically reduce recovery time when failover happens.

# NOTE 2: You cannot use "create-db-instance-read-replica" with an Aurora db cluster.
# Instead, we need to use "create-db-instance" to start a new instance in the cluster.
# Use the same syntax and JSON template as you used for the primary Aurora instance,
# but specify a new availability zone. Aurora automatically designates the new db instance as a Read Replica
# and will automatically update the value of "Multi AZ" parameter in the db instance details.
# Read the next note for details.

# NOTE 3: Aurora "clusters" refer to the collection of a single physical database instance
# and its physical replicas, that all server the same data (stored in a single or several logical databases).
# The concept of  cluster in Aurora is different from an EC2 cluster where each instance is an independent
# physical resource and each can serve a different set of data and functionality.
# Instead, an Aurora cluster is just a group of db instances that all server the same set of databases.
# One of these instances is the primary instance (Role: Writer) and the subsequent instances
# that are added to the Aurora cluster are Read Replicas (Role: Reader).
# That is why in order to add a Read Replica, we simply need to create a new db instance in the db cluster.
# Aurora will automatically replicate the data from the primary instance, update the role of the new instance,
# and update the MultiAZ property of the db cluster instances.
# https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance-read-replica.html
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.CreateInstance.html
# https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
dbcluster_reponse=$(aws rds create-db-instance --db-instance-identifier ${db_instance_name}-replica-us-west-2b \
    --availability-zone us-west-2b \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/create_db_instance.json)

