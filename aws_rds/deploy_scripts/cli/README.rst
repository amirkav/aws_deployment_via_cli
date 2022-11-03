
The scripts in this directory are not directly used as part of the deployment codebase.
They are CLI scripts that follow the cluster deployment step-by-step.
Their main goal is development and debugging.

The main deployment process is performed using CloudFormation Templates and wrapper scripts.
But, CFTs are hard to visualize and follow. In case of debugging or the need to add new
features to the process, we need a more hands-on codebase. These scripts address that need.



===================
CLI Commands
===================
These are the commands to start and manage an RDS cluster:

aws rds create-db-cluster --generate-cli-skeleton
aws rds create-db-instance --generate-cli-skeleton

aws rds create-db-cluster-parameter-group --generate-cli-skeleton
aws rds create-db-parameter-group --generate-cli-skeleton
aws rds create-option-group --generate-cli-skeleton

aws rds create-db-cluster-snapshot --generate-cli-skeleton
aws rds create-db-instance-read-replica --generate-cli-skeleton
aws rds create-db-cluster-snapshot --generate-cli-skeleton
aws rds create-db-snapshot --generate-cli-skeleton


aws rds restore-db-cluster-from-snapshot --generate-cli-skeleton
aws rds restore-db-cluster-to-point-in-time --generate-cli-skeleton
aws rds restore-db-instance-from-db-snapshot --generate-cli-skeleton
aws rds restore-db-instance-to-point-in-time --generate-cli-skeleton


============
Monitoring
============
# At any point in time, to see the recent events in RDS:
aws rds describe-events


################
zip reference
################
The most basic form:
$ zip -r [target_file] [source_file]


=======================
Compression intensity
=======================
To increase compression, add a digit to the parameters.
$ zip -r9 [target_file] [source_file]
Number parameter means degree of compression.
-9 is the most optimal but the slowest compression.
If -0 is given, there will be no compression. Default level is -6.


=============================
File or directory exclusion
=============================
To exclude files or directories from a compressed folder, use -x parameter.
For example, the following excludes .git file and node_modules directory:
$ zip -r9 [target_file] [source_file] -x *.git* node_modules/\*
Or, to exclude .git file and files in node_modules directory, but keep node_modules directory:
$ zip -r9 [target_file] [source_file] -x *.git* node_modules/**\*

The parameter "**" means to adapt exclusions recursively inner directories.
The parameter "\*" is an escaped wildcard to avoid path expansion.


