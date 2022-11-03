

##########################
Lambda Functions
##########################


======================================
VPC Configs for Lambda functions
======================================
We used public subnets and public SG ids for VPC configs,
because for now our RDS cluster is deployed in public subnets.
This may change if we write a front-end for the product and
redact public access to db tables. When we move the db cluster
to private subnets, remember to move the lambda functions to private
subnets and SGs too.

To access both SSM and RDS, we need to:
- add private subnets
- add both public and private security groups.



#######################################
### Options for creating the Lambda function
# Option 1: Keep the python code in git repo,
# and create the Lambda function using the CLI.
# If you decide to keep the python code in your repo,
# follow through this file.

# Option 2: store the python code on S3,
# and create the Lambda function using the CLI.
# First upload the Lambda zip file to S3, then
# change the "--zip-file" parameter in the CLI command below to:
# --code S3Bucket=bucket-name,S3Key=zip-file-object-key

# Option 3: store the python code on S3,
# and create the Lambda function using a CloudFormation Template.
# First, upload the python code to an S3 bucket and refer to it in the CFT.
# Then, define the Lambda function as a "AWS::Lambda::Function" resource in a CFT.
# I have included the CFT that can create a Lambda function and its associated IAM Role
# in the db_cluster/templates/ directory.
# That CFT refers to an S3 bucket where the lambda zip file is stored.

# NOTE 4: create the Lambda function using a CloudFormation Template
# and specify the python code as inline text in the template.
# https://stackoverflow.com/questions/44048645/stack-creation-is-hanging-on-create-in-progress
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-lambda-function-code.html
# https://stackoverflow.com/questions/43976305/lambda-function-in-aws-cloudformation
#######################################


#######################################
### Lambda Deployment Workflow
# Follow this tutorial for how to do versioning and deployment control for Lambda:
# https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases-walkthrough1.html

# We can only update the $LATEST version.
# We can publish a version at any point.
# Versions work like snapshots: they help keep a reference
# to a lambda function at a specific point in time.
# Aliases are dynamic references to versions.
# We can change the version number that they refer to,
# without changing the alias itself.
# Aliases are useful for managing both downstream and upstream dependencies.
# Use versions to create snapshots of lambda functions,
# so you can continue developing a lambda function without braking the PRODUCTION code.
# If there are dependencies associated with the lambda function,
# use alias qualifiers to ensure those dependencies
# dont break as we cut new versions for the lambda function.
#######################################
