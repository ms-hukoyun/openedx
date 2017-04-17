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
USE_MSFT_FORK=$2 # optional

echo "updating packages..."
sudo apt-get update -y -qq --fix-missing
sudo apt-get upgrade -y -qq --fix-missing

sudo -H bash install-openedx.sh "open-release/eucalyptus.1" $STACK_TYPE $USE_MSFT_FORK | tee /tmp/openedx-install.log
