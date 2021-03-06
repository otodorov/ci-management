#!/bin/bash
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

CA_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')
echo "========> $CA_TAG"
echo
NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"

# Push docker images to nexus docker repository

dockerCaPush() {

  # shellcheck disable=SC2043
  for IMAGES in ca ca-peer ca-orderer ca-tools; do
    echo "==> $IMAGES"
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$CA_TAG
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CA_TAG"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$CA_TAG
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CA_TAG"
    echo
  done
}

dockerCaPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
