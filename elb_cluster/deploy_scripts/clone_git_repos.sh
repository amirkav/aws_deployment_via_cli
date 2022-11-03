#!/bin/bash

### CLONE GIT REPOS
# AWS CloudFormation currently does not support Secure Strings.
# We dont want to include our github account credentials in user-data.log file.
# As a result, instead of running this code directly in UserData section of a CFT,
# we run it as a shell script called from UserData.
# When called as a shell script, raw commands do not show up
# in user-data.log file.
# https://www.reddit.com/r/aws/comments/69qzha/how_to_prevent_secrets_from_displaying_in/
# https://forums.aws.amazon.com/thread.jspa?threadID=255650


# read the credentials from parameter store
GH_CREDS=$(aws ssm get-parameters --names "BBS-Seneca-Secret-GithubCredentials-Encrypted" --with-decryption --region "us-west-2")
export GH_PASS=$(echo $GH_CREDS | jq '.Parameters[0].Value' --raw-output)
export GH_USER=amirkav


# clone git repos
sudo mkdir -p ${GITS_DIR}
cd ${GITS_DIR}

sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/tools.git"
sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/aurelius.git"
sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/lucius.git"

sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/sphaerus.git"

sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/uphrates.git"
sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/diogo.git"
sudo git clone -b develop "https://${GH_USER}:${GH_PASS}@github.com/altitudenetworks/nicos.git"

# aws s3 cp ${GITS_DIR}/aurelius/git/clone_git_repos.sh s3://bbs-seneca-conf/clone_git_repos.sh
