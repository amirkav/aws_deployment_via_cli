
# Lambda jobs dev & dep

The goals is to deploy one lambda for all projects, and invoke it multiple times, one for each project.
- If we add PROJECT_NAME as a env var, then we need one deployment per project. This is decided in "Environment" property of "AWS::Serverless::Function" resource in lambda CFT.
- If we add project_name as an Input to the CloudWatch Events Rule, then we can have a single lambda deployment, and invoke it for all projects. This is decided in the Target property of "AWS::Events::Rule" in lambda CFT.
- In both cases above, we will still pass ProjectName as a "Parameter" to the lambda CFT.

#NOTE: this is how function parameters flow through lambda functions:
CW Events Rule > Orchestrator function > Worker Function > SQS Message > Uploader Function
Using env vars, we can short-circuit some of these hand-offs. But, that comes at the cost of less flexibility: we will need to deploy an individual lambda function per project, SQS queue, etc.
- Every time we add a new parameter to "Event", we need to update these places:
1. set_env_vars: input parameters, env_vars.json file, ENV_VARS variable
2. create_stack.sh: command line parameters
3. CFT: CloudWatchScheduledEventRule, ENV_VARS
4. Unit tests: Events
5. Orch lambdas: boto3 invoke payload


# Summary of Lambda Invocations

- scraper
-- orchestrator (CloudWatch Events, asynchronous, 'Event')
-- worker (orchestrator lambdas via boto3, asynchronous, 'Event')

- uploader
-- [all] (sqs via lambda long-polling, synchronous, 'RequestResponse' invocation)


Resources:
https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-function.html
https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html
https://docs.aws.amazon.com/lambda/latest/dg/eventsources.html#eventsources-sqs
https://docs.aws.amazon.com/lambda/latest/dg/invocation-options.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/RunLambdaSchedule.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html

## Python and Non-Python Dependencies
#QUESTION: Can I use the python packages as installed on python to linux?
Can I pip install python dependencies on my machine,
and upload them to lambda directly?
Or, do the python packages have to be created in linux to be usable by lambda?

If yes, then the current way is the right way to do it:
- spin up an EC2 instance
- install python dependencies on it.
- create a zip file from it and put it on S3.
- download it when we need lambda packaging.
- add lambda handlers to it and upload it to S3 again.


## Reduce lambda package size
GOAL: Reduce lambda package size to speed up dev and deployment.

~ Fix code packaging: only package those libraries
that are *not* part of standard python libraries.

~ Copy Altitude packages to lambda package folder instead of 'pip install' them.
Copying python packages ended up being 1.6MB,
compared to 14MB when I 'pip install' my packages into lambda folder.

~ Install python dependencies separately from installing the git repo.
Keep the requirements.txt file as is to be able to install my git repos.

TODO: Create a slimmed-down version of the CFT to create Linux external libraries package.

https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html



## Increase dev update speed
GOAL: During development, I want to be able to make change and quickly see the results,
not having to run long scripts or upload/download large packages from pip or S3.


### Option a: import via relative paths
instead of relying on pip installs of your repos.
This will enable us to to live dev and testing:
we don't have to reinstall git repos every time we make changes to a script in another python package.

To make relative paths work, we need to modify PYTHONPATH and/or sys.path.
There are drawbacks to doing that, and it may create compatibility issues.
https://stackoverflow.com/questions/1893598/pythonpath-vs-sys-path
https://leemendelowitz.github.io/blog/how-does-python-find-packages.html


By default, sys.path is constructed as a concatenation of
(1) the current working directory,
(2) content of PYTHONPATH environment variable, and
(3) a set of default paths supplied by the installed Python interpreter.
These paths are specified in the {python_installed_dir}/site.py file
of installed python interpreter.
To find the location of site.py:
>>> import site
>>> print(site.__file__)
>>> import sys
>>> print("sys.path:{}".format(sys.path))
>>> import os
>>> print("PYTHONPATH: {}".format(os.environ['PYTHONPATH']))



To add Altitude python packages to python's search path, follow these steps:
- Add $GITS_DIR to PYTHONPATH env var.
export PYTHONPATH=${PYTHONPATH}:${VENV_DIR}:${GITS_DIR}:${CONF_DIR}
#ISSUE: How to set PYTHONPATH inside SAM Local container?

- Instruct sys.path picks up the PYTHONPATH env var.

- For each package, add a __init__.py file
in the root to make the root a python package.

- When importing a package, add one more level of package name to the import statement:
>>> import tools.tools.s3_connect as S3Connect

- "pip uninstall" all altitude packages


### Option b: import repos as pip packages
#TODO: Add it to your workflow to run
'pip install --upgrade ${GITS_DIR}/${git_repo}'
when you make changes to a different repo than the one you are working on.


## Automatically get the name of the latest lambda function deployed
# https://alvinalexander.com/unix/edu/examples/sort.shtml
# https://unix.stackexchange.com/questions/10524/how-to-numerical-sort-by-last-column
# https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
# http://www.unixcl.com/2010/11/sort-file-based-on-last-field-unix.html
