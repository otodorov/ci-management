#!/bin/bash -e
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -o pipefail

# Build fabric-ca images
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca || exit

# Publish fabric-ca docker images
NEXUS_URL=nexus3.hyperledger.org:10002
# get the GOARCH value (ex: amd64, s390x)
ARCH=$(dpkg --print-architecture)
# PUSH_VERSION comes from Jenkins environment variable
echo "================="
echo "-------> BUILD DOCKER IMAGES <---------"
make docker PROJECT_VERSION=$PUSH_VERSION
if [ $? != 0 ]; then
     echo "--------> make docker failed"
     exit 1
fi

# List all docker images
docker images

if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
     ARCH=x86_64
else
     ARCH=$(dpkg --print-architecture) # amd64, s390x
     echo "----------> ARCH:" $ARCH
fi

# publish fabric-ca docker images from release-1.0
if [ "$GERRIT_BRANCH" = "release-1.0" ]; then
     docker tag hyperledger/fabric-ca:$ARCH-$PUSH_VERSION $NEXUS_URL/hyperledger/fabric-ca:$ARCH-$PUSH_VERSION
     docker push $NEXUS_URL/hyperledger/fabric-ca:$ARCH-$PUSH_VERSION
     echo "--------> Push fabric-ca Image version:" $NEXUS_URL/hyperledger/fabric-ca:$ARCH-$PUSH_VERSION
else
# publish fabric-ca docker images otherthan release-1.0 branch
     for IMAGES in ca ca-peer ca-tools ca-orderer; do
          docker tag hyperledger/fabric-$IMAGES:$ARCH-$PUSH_VERSION $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$PUSH_VERSION
          docker push $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$PUSH_VERSION
          echo "--------> Push fabric-ca Image version:" $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$PUSH_VERSION
     done
fi
