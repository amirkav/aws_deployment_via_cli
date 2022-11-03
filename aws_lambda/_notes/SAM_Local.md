# SAM Local 


**SAM Local Limitations**
SAM Local does not evaluate CloudFormation "conditionals".
CFN intrinsic functions has a lot of dense logic
which is not practical to evaluate in its entirety.


Source:
https://github.com/awslabs/aws-sam-cli/issues/194



## Use YAML templates
NOTE: SAM is designed to be compatible with YAML templates.
Its behavior when working with JSON files is unpredictable.
So, write your lambda templates in YAML format.

SAM does not read "CodeUri" properly
when the template is stored in JSON format,
but it works when using YAML format.

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-serverless.html
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stacks-changesets.html
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets-execute.html
https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md


## Use Lambda's Logical ID
NOTE: We use function's logical ID to invoke them using sam local.
But, when invoking using aws cli commands, we refer to the function
by their global name (the name by which they are listed on AWS Console).


## Include env vars inside the template
NOTE: You can add env vars to a separate file and
passing them to the lambda at the time of invoking it.
   --env-vars ${lambda_path}/deploy_configs/env_vars.json \
But, SAM Local only parses environment variables that are defined in the SAM template.
So, for SAM Local, include env vars in the template file, not separate JSON file.
https://stackoverflow.com/questions/48104665/aws-sam-local-environment-variables

#ISSUE: SAM Local does not pick up properly
environmental variables that we pass to it in template file.

NOTE: Ensure that the variables are declared in template.yml.
A config file overwrites the variables,
but does not create variables when they don't exist in the original template.
https://stackoverflow.com/questions/48104665/aws-sam-local-environment-variables

NOTE: SAM Local does not override host's environmental variables,
using env vars that we pass to it in the template.
If you want to override host machine's env vars, provide an env_vars.json file.

NOTE: It is a known issue (or feature) that we cannot set
env vars inside the 'Globals' section of the template.
So, make sure you add the env vars section inside Function hierarchy.
https://github.com/awslabs/aws-sam-cli/issues/245

# Following is the order of priority for sam to read env vars, highest to lowest:
#   (a) Environment variable file
#   (b) Shell environment
#   (c) Hard-coded values contained in the SAM template
# Source: https://docs.aws.amazon.com/lambda/latest/dg/test-sam-cli.html#sam-cli-what-is

SUMMARY: If you want to include env vars in your lambda function,
note that SAM Local will read and override their values in the following order:
(1) SAM Local will read the list of env vars and their values from the template file.
(2) If the host machine has the same env vars as defined in the template file,
    SAM Local will override their values by the value of
    the same env vars in the host machine.
    But, SAM Local will not use host machine env vars
    if they are not defined in the template file.
(3) If an env var JSON file is provided,
    SAM Local will override those values with
    the values provided in the JSON file.
    Similar to point (2) above, the JSON file does not create new env vars;
    it just override existing env vars that are defined in the template.

ACTION ITEMS: To set the env vars inside your lambda function:
(a) Declare the env vars that your lambda needs in the template file.
(b) If the values of env vars inside the lambda are different from its host machine,
    provide an env vars JSON file to override the values of host's env vars.



## Mounting directories to SAM Local
ISSUE: SAM Local does not mount a working directory for unzipping CodeUri.
As a result, SAM Local cannot find config.json file.

The problem is that the docker container that runs SAM Local
does not mount $HOME directory (or any directory other than the CodeUri dir)
into its filesystem.

A related issue: SAM Local gives a "Permissions denied" error when CodeUri is a zip folder.
We need to unzip the folder before using it in the template.
This is because when trying to decompress a .jar or .zip,
SAM Local tries to do that by using the path the file has in the host, rather than the local path.

SAM Local does not mount $HOME directory in its Docker container.
Lambda functions only have one writable folder: "/tmp".
That means the Docker container that run the lambda function
only mounts the /tmp folder. We have already fixed
our lambda code to set env vars to use /tmp folder.

SOLUTIONS: try the following potential solutions:
- Download the config.json file to /tmp directory, similar to what you do in the actual lambda script.
    For this, you will need to change the $CONF_DIR location to /tmp/.credentials instead of $HOME/.credentials.
    It may be worth changing all /opt references to /tmp as well.
- Learn how to mount other directories to SAM Local Docker container.
- Include config.json in the build directory for each lambda function.

https://github.com/awslabs/aws-sam-cli/issues/130


## Referencing python packages with relative paths inside SAM Local
sys.path and PYTHONPATH are not the same necessarily.

#TODO: get python to override sys.path with SYSTEMPATH.



## Connecting to MySQL db from SAM Local
For lambda functions that need access to a local database (eg, for testing purposes),
use Docker's localhost pointer:
https://stackoverflow.com/questions/47440757/mysql-data-base-connection-inside-sam-local

For lambda functions that need access to resources within VPC, use "VpcConfig" parameter
to enable the function to access private resources within your VPC.
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-lambda-function-vpcconfig.html


## Using Global Resources for SAM template
We can share resources, env vars, and more across different resources,
by including them in the "Globals" section of the template.
https://github.com/awslabs/serverless-application-model/blob/master/docs/globals.rst


## Packaging the lambda scripts
https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html
https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html


## Authentication and Access Control
https://docs.aws.amazon.com/lambda/latest/dg/lambda-auth-and-access-control.html


### Policy Templates
Use policy templates to give SAM Local enough permissions to run the lambda job, but not too much permission.
https://github.com/awslabs/serverless-application-model/blob/master/docs/policy_templates.rst



# RESOURCES
SAM Intro
https://docs.aws.amazon.com/lambda/latest/dg/test-sam-cli.html#sam-cli-what-is

SAM Docs
https://github.com/awslabs/serverless-application-model/tree/master/docs

SAM Template Specs
https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md

CFN Compatibility
https://github.com/awslabs/serverless-application-model/blob/master/docs/cloudformation_compatibility.rst

SAM How To
https://github.com/awslabs/serverless-application-model/blob/master/HOWTO.md

SAM Codebase
https://github.com/awslabs/serverless-application-model

SAM CLI README
https://github.com/awslabs/aws-sam-cli/blob/develop/README.rst

SAM CLI Codebase
https://github.com/awslabs/aws-sam-cli/

SAM's Docker Specs
https://github.com/lambci/docker-lambda

AWS Serverless Examples
https://github.com/awslabs/serverless-application-model/tree/master/examples/2016-10-31

SAM Local Background
https://blog.rowanudell.com/getting-started-with-aws-sam-local/

SAM Local w Neo4j, Docker
https://laeg.github.io/sam-neo4j-lambda-docker/

