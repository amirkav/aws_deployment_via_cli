#!/usr/bin/env bash

# Publishes a version of your function from the current snapshot of $LATEST.

# Versions are used as an archival and backup method.
# Versions can be compared to software releases.
# Once we deploy a stable lambda function that we want to keep
# (e.g., in prod), we publish a version as a backup.
# Unless we specifically update lambda alias,
# our la,bda ARN and its alias will not point to
# the new version. We can update an existing alias
# or create a new alias to point to the new version.
# For instance, we can create a "prod" alias and
# point it to the published version. This way, even
# if the new versions of the lambda function break,
# the published version and the "prod" alias will work.

# Unless you choose to publish versions,
# the $LATEST function version is the only Lambda function version that you have.
# We can choose to publish a new lambda version after a major refactor.
# With multiple versions, we can have different lambda aliases refer to
# different versions, and create a production environment.

# Each time you publish a version, AWS Lambda copies $LATEST version
# (code and configuration information) to create a new version.

# NOTE: We have a AWS::Lambda::Version in the CFN template,
# which creates Version 1 of our lambda function.

# https://docs.aws.amazon.com/lambda/latest/dg/versioning-intro.html
# https://docs.aws.amazon.com/cli/latest/reference/lambda/publish-version.html

# NOTE: No need to run this if you specify '--publish' parameter in 'update-lambda-code' command.
publish_version_resp=$(aws lambda publish-version \
    --function-name ${lambda_function_name})

export lambda_function_version=$(echo $publish_version_resp | jq '.Version' | sed -e 's/"$//' -e 's/^"//')

