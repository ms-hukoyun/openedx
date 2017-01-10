#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Create LXC VM for 12.04.5
# sudo lxc-create -t download -n myNode -d ubuntu -r precise -a amd64

# Parameter specifying fullstack or devstack
STACK_TYPE=full # default to full when not provided.
if [ ! -z $1 ]; then
    STACK_TYPE=$1
fi
# Restrict parameter to supported values: full | dev
if [ $STACK_TYPE != "dev" ] && [ $STACK_TYPE != "full" ]; then
    echo "Please specify fullstack or devstack (with argument full or dev)"
    echo "Exiting script"
fi

echo "updating packages..."
sudo apt-get update -y -qq --fix-missing
sudo apt-get upgrade -y -qq --fix-missing

sudo bash install-openedx.sh "open-release/eucalyptus.1" $STACK_TYPE | tee /tmp/openedx-install.log
