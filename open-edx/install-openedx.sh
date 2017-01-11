#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

verify_file_exists()
{
    FILE_PATH=$1
    if [ ! -f $FILE_PATH ]; then
        echo "No file exists at path: $FILE_PATH"
        echo "Exiting script"
        exit
    fi
}

export OPENEDX_RELEASE=$1
STACK_TYPE=$2
# Note: if we need to make a change then make it in our fork. Change the following values
# Note: also, see the note below
export CONFIGURATION_VERSION=$1 # oxa/master
CONFIG_FOLDER=configuration # edx-configuration
CONFIG_ORG=edx # Microsoft
CONFIG_REPO=https://github.com/$CONFIG_ORG/$CONFIG_FOLDER.git
ANSIBLE_ROOT=/edx/app/edx_ansible
TEMP_DIR=/var/tmp

if [ ! -f "/etc/ssh/sshd_config" ]; then
    echo "installing ssh..."
    sudo apt-get install -y -qq ssh
fi

pushd $TEMP_DIR
git clone $CONFIG_REPO
pushd $CONFIG_FOLDER
git checkout $CONFIGURATION_VERSION
verify_file_exists "./util/install/ansible-bootstrap.sh"
bash util/install/ansible-bootstrap.sh
popd
popd

bash -c "cat <<EOF >extra-vars.yml
---
edx_platform_version: \"$OPENEDX_RELEASE\"
certs_version: \"$OPENEDX_RELEASE\"
forum_version: \"$OPENEDX_RELEASE\"
xqueue_version: \"$OPENEDX_RELEASE\"
configuration_version: \"$OPENEDX_RELEASE\"
edx_ansible_source_repo: \"$CONFIG_REPO\"
COMMON_SSH_PASSWORD_AUTH: \"yes\"
EOF"
cp *.yml $ANSIBLE_ROOT
chown edx-ansible:edx-ansible $ANSIBLE_ROOT/*.yml

pushd $TEMP_DIR/$CONFIG_FOLDER
# Note: See note above. This will work for dogwood and eucalyptus
# Note: Enable this checkout if you are using our fork. This is required until get all the latest branches from the upstream.
#git checkout open-release/eucalyptus/master
verify_file_exists "./requirements.txt"
pip install -r requirements.txt

pushd playbooks
verify_file_exists "vagrant-${STACK_TYPE}stack.yml"
verify_file_exists "$ANSIBLE_ROOT/server-vars.yml"
verify_file_exists "$ANSIBLE_ROOT/extra-vars.yml"
ansible-playbook -i localhost, -c local vagrant-${STACK_TYPE}stack.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra-vars.yml
popd
popd
