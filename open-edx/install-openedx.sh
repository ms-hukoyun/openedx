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
        exit 3
    fi
}
verify_hkp_service()
{
    sudo apt-key adv --keyserver "pgp.mit.edu" --recv-keys 69464050
    if [ $? -ne 0 ]; then
        echo "Port 11371 is blocked"
        echo "Please change EDX_PPA_KEY_SERVER to hkp://pgp.mit.edu:80 in"
        pwd
        echo "/util/install/ansible-bootstrap.sh"
        exit 5
    fi
}
verify_ssh()
{
    if [ ! -f "/etc/ssh/sshd_config" ]; then
        echo "installing ssh..."
        sudo apt-get install -y -qq ssh
    fi
}

export OPENEDX_RELEASE=$1
STACK_TYPE=$2

export CONFIGURATION_VERSION=$1
CONFIG_FOLDER=configuration
CONFIG_ORG=edx
# Note: if we need to make a change to ansible-bootstrap.sh or requirements.txt then we'll make it in our fork.
if [ ! -z $3 ]; then
    echo "Use Microsoft's fork for ansible-bootstrap.sh and requirements.txt"
    export CONFIGURATION_VERSION=oxa/master
    CONFIG_FOLDER=edx-configuration
    CONFIG_ORG=Microsoft
fi

CONFIG_REPO=https://github.com/$CONFIG_ORG/$CONFIG_FOLDER.git
ANSIBLE_ROOT=/edx/app/edx_ansible
TEMP_DIR=/var/tmp

verify_ssh

pushd $TEMP_DIR
git clone $CONFIG_REPO
pushd $CONFIG_FOLDER
git checkout $CONFIGURATION_VERSION
verify_file_exists "./util/install/ansible-bootstrap.sh"
verify_hkp_service
bash util/install/ansible-bootstrap.sh
if [ $? -ne 0 ]; then
    echo "ansible-bootstrap.sh script failed"
    exit 7
fi
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
# This is required until we get all the latest branches from the upstream and/or merge latest changes into oxa/master
if [ ! -z $3 ]; then
    # This will work for dogwood and eucalyptus
    git checkout open-release/eucalyptus/master
fi
verify_file_exists "./requirements.txt"
pip install -r requirements.txt

pushd playbooks
verify_file_exists "vagrant-${STACK_TYPE}stack.yml"
verify_file_exists "$ANSIBLE_ROOT/server-vars.yml"
verify_file_exists "$ANSIBLE_ROOT/extra-vars.yml"
ansible-playbook -i localhost, -c local vagrant-${STACK_TYPE}stack.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra-vars.yml
popd
popd
