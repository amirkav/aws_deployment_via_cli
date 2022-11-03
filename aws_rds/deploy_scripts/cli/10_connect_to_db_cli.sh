#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

### Non-SSL connection
# Normal connection, using instance endpoint.
# Preferably dont use this. If you have to directly
# connect to a db instance (eg, when connecting via SSL), make sure
# to connect to the primary instance so that RDS would
# replace it with a read replica in case of failover.
# Ie, when the primary instance of a cluster fails over,
# RDS automatically replaces it with a standby read replica and
# updates the DNS record for the DB instance to point to
# the standby replica DB instance, so we dont experience any
# service disruption.
$ mysql -h rds-instance-seneca-1.cvbzyez350zi.us-west-2.rds.amazonaws.com -P 3306 -u bbsdbuser -p
$ mysql -h rds-cluster-dev-atlas-27.cluster-ro-cvbzyez350zi.us-west-2.rds.amazonaws.com -P 3306 -u <master_user> -p

# Normal connection, using cluster reader endpoint (preferred)
$ mysql -h rds-dbcluster-seneca-1.cluster-ro-cvbzyez350zi.us-west-2.rds.amazonaws.com -P 3306 -u bbsdbuser -p

# Normal connection, using cluster endpoint (for write purposes)
$ mysql -h rds-dbcluster-seneca-1.cluster-cvbzyez350zi.us-west-2.rds.amazonaws.com -P 3306 -u bbsdbuser -p


# Connecting via SSL
# If the SQL client that you are using supports SAN, then use the Reader Endpoint of the cluster.
# Otherwise, we have to use the DB instance endpoint.
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Security.html
$ mysql -h rds-instance-seneca-1.cvbzyez350zi.us-west-2.rds.amazonaws.com -P 3306 --ssl-ca=/Users/ak/gits/seneca/db_deployer/mysql/deploy_configs/rds-combined-ca-bundle.pem --ssl-mode=VERIFY_IDENTITY -u bbsdbuser -p