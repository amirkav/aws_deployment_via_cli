
==================================
Problem Statement
==================================
A note about the CfnParamStore Lambda function and
associated Cloudformation Stack Template: cfn-param-store.yml

When creating a new DB Cluster, we need to provide a Master Username and Master Password.
Master username cannot be changed later; but, we can change master password later.
https://aws.amazon.com/premiumsupport/knowledge-center/reset-master-user-password-rds/

We dont want to include the master username and password in the CFT directly.
Instead, we want to put the master user and pass on AWS Parameter Store and encrypt it,
and pull the username/password when creating the CloudFormation Stack.
https://aws.amazon.com/blogs/mt/integrating-aws-cloudformation-with-aws-systems-manager-parameter-store/

CloudFormation supports Parameter Store; i.e., we can refer to
parameters stores in Parameter Store in CFN templates.
But, CFN does not support "Secure Strings" (aka encrypted parameters) inside a CFT.
This is a temporary limitation and will be resolved later.
https://forums.aws.amazon.com/thread.jspa?messageID=803047

For now, until secure strings are supported in CFT, we need to
use a Lambda function to decrypt secure strings
as we read them from the Parameter Store.
The Lambda function "CfnParamStore" does that; ie,
it decrypts the parameters that we have stores in Param Store
and returns decrypted values to us.
https://github.com/glassechidna/ssmcfn


IMPORTANT UPDATE: The CfnParamStore lambda function does not solve the problem we outlined above.
The Lambda function CREATES a new encrypted parameter on Parameter Store for us.
But, we still have to generate the value of the parameter and pass it on to the CFT.
It does not decrypt and read the secure parameter into CFT for us;
it does the opposite: it receives our parameter and stores it as a secure (encrypted) parameter on Parameter Store.

Currently, there is no good way of reading secure strings into a CFT. Instead,
I am using a separate CLI script to create a password for the db on Secrets Manager.
Secrets Manager will automatically encrypt and rotate the password.


==================================
How to deploy the Lambda function
==================================
To make it easier to deploy the Lambd function, we have written a CFN stack that automatically deploys the
Lambda function. This stack is called "CfnParamStore-..."

$ cd ${GITS_DIR}/db_deployer/mysql/templates
$ aws cloudformation create-stack --stack-name CfnParamStore-${env}-${stack_suffix} \
    --template-body file://./cfn-param-store.yml \
    --capabilities CAPABILITY_IAM

Or, use the shell wrapper 20_deploy_cfn_paramstore_lambda.sh
$ cd ${GITS_DIR}/db_deployer/mysql/deploy_scripts
$ . 20_deploy_cfn_paramstore_lambda.sh


==================================
How to use the Lambda function
==================================
We cannot embed a Lambda function in "Parameters" or "Mappings" section of CFT.
Instead, we can only use them in Resources section.
So, to use our Lambda function to decrypt our parameter values,
we need to create separate resources for each of the parameters,
with the following syntax.

Note that in this case, I have also parametrized the name of the Parameter (its key)
in the "Mappings" section of the CFT, and then have referred to it in the "Value" section
of the resource. But, we could have easily hard-code the name of the parameter too.



  "Resources": {

    "DBMasterUser" : {
      "Type" : "Custom::CfnParamStore",
      "Properties": {
        "ServiceToken" : { "Fn::ImportValue" : "CfnParamStore"},
        "Type" : "SecureString",
        "Value" : {"Fn::FindInMap": [{"Ref": "Env"}, {"Ref": "AWS::Region"}, "dbMasterUserParamName"]}
      }
    },
    "DBMasterPass" : {
      "Type" : "Custom::CfnParamStore",
      "Properties": {
        "ServiceToken" : { "Fn::ImportValue" : "CfnParamStore"},
        "Type" : "SecureString",
        "Value" : {"Fn::FindInMap": [{"Ref": "Env"}, {"Ref": "AWS::Region"}, "dbMasterPassParamName"]}
      }
    },

  }


============================================================================
(future) How to use CloudFormation integration with Secure Strings support
============================================================================
AWS will eventually fix this issue and will have CloudFormation
support SecureStrings in the Parameters section of templates.

When AWS releases the update and starts to support Secure Strings CloudFormation,
we wont need the Lambda function anymore.
Instead, we can simply use the following syntax in the "Parameters" section
of CloudFormation templates.

  "Parameters": {

    "MasterUser" : {
      "Description" : "Master username for MySQL database.",
      "Default" : "BBS-Atlas-DB-Master-User-Encrypted",
      "Type" : "AWS::SSM::Parameter::Value<SecureString>",
      "NoEcho" : "true"
    },

    "MasterPass" : {
      "Description" : "Master password for MySQL database.",
      "Default" : "BBS-Atlas-DB-Master-Pass-Encrypted",
      "Type" : "AWS::SSM::Parameter::Value<SecureString>",
      "NoEcho" : "true"
    },
  }


Then, we can refer to these as normal parameters.
    {"Ref": "OwnerContact"}


We can remove the following parameters from "Mappings" section:
dbMasterUserParamName
dbMasterPassParamName

And we can remove the following resources from Resources section:
DBMasterUser
DBMasterPass




#TODO: Delete after debugging...

    "MasterUser" : {
      "Description" : "Master username for MySQL database.",
      "Default" : "BBS-Atlas-DB-Master-User-Unencrypted",
      "Type" : "AWS::SSM::Parameter::Value<String>",
      "NoEcho" : "true"
    },

    "MasterPass" : {
      "Description" : "Master password for MySQL database.",
      "Default" : "BBS-Atlas-DB-Master-Pass-Unencrypted",
      "Type" : "AWS::SSM::Parameter::Value<String>",
      "NoEcho" : "true"
    },

