
################################################
Targets.json file for CloudWatch Events Rule
################################################

### Create a targets config JSON file for CloudWatch Events Rule Target creation
# We will refer to targets.json file in "aws events put-targets" command,
# when we are creating the CW Events Rule.
# In CFTs, we do this by changing the "Input" parameter
# of "Targets" property of "AWS::Events::Rule" resource.

### PURPOSE
# The Input parameters passed
# to the lambda by CloudWatch Events are useful when our parameter
# values change between different invocations of the lambda function.
# For example, if you want to pass constant (static) input to the lambda function
# (e.g., the name of a downstream lambda function or an SNS topic),
# use the "Input" or "InputPath" property of "targets" parameter.

# If there are input parameters that are constant across all
# invocations of the lambda function (eg, path to install the code),
# then we can use environmental variables to "hard-code" those
# parameters in the lambda function.

# Note: When you pass on static data as "Input" to the lambda function,
# nothing of the event itself will be passed to the target lambda function.
# I.e., this json payload will supersede Lambda's default 'event' parameter.

# https://aws.amazon.com/blogs/compute/simply-serverless-use-constant-values-in-cloudwatch-event-triggered-lambda-functions/
# https://docs.aws.amazon.com/cli/latest/reference/events/put-targets.html
# https://docs.aws.amazon.com/AmazonCloudWatchEvents/latest/APIReference/API_PutTargets.html
# https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-function.html

### FORMATTING
# aws cli requires that the "Input" entry of the target json file
# be in string data type, but written in json format.
# So, we need to write a string object that will be translated to a json object
# by aws cli. To write the string object, we had to use the following tricks:
# (a) The JSON format requires quotation marks around its keys and values.
#     We escaped those internal quotation marks using backslash.
# (b) Bash JSON format does not accept multi-line strings (does not recognize or skip newline character).
#     But, writing all input parameters in one line would make our code hard to read and debug.
#     To get around this limitation, we used the bash heredoc pattern
#     to write a multiline string to a temporary bash variable (input_string)
#     We escaped newline characters using bash 'read' command,
#     where -d'' causes it to read multiple lines (ignore newlines).
# https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
