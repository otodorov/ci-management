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

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

# Clone fabric-samples.
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

echo "######## Cloning fabric-samples ########"
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

# copy /bin directory to fabric-samples

if [ "$ARCH" == "s390x" ]; then
   cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-s390x/bin/ .
else
   cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .
fi

cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done

if [ ! -z $2 ]; then

    for CONTAINER in ${COUCHDB_CONTAINER_LIST[*]}; do
        docker logs $CONTAINER >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
        echo
    done
fi
}

copy_logs() {

# Call logs function
logs $2 $3

if [ $1 != 0 ]; then
    artifacts
    exit 1
fi
}

# Execute below tests
echo "------> BRANCH: " $GERRIT_BRANCH
echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###################"
echo "#################################################################"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m up -t 60
copy_logs $? default-channel
echo y | ./eyfn.sh -m up -t 60
copy_logs $? default-channel
echo y | ./eyfn.sh -m down
echo
: '
echo "############## BYFN,EYFN CUSTOM CHANNEL TEST ############"
echo "#########################################################"

echo y | ./byfn.sh -m up -c custom-channel -t 60
copy_logs $? custom-channel
echo y | ./eyfn.sh -m up -c custom-channel -t 60
copy_logs $? custom-channel
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
echo "#########################################################################"
'
echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
copy_logs $? custom-channel-couch couchdb
echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
copy_logs $? custom-channel-couch couchdb
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
echo "####################################################################"

echo y | ./byfn.sh -m up -l node -t 60
copy_logs $? default-channel-node
echo y | ./eyfn.sh -m up -l node -t 60
copy_logs $? default-channel-node
echo y | ./eyfn.sh -m down

if [ "$ARCH" == "s390x" ]; then
    echo "-------> SKIP fabric-ca tests on s390x platform"
    echo "Unable to build fabric-ca-fvt docker image after upgrade the"
    echo "debian to stretch from jessie"
else
    echo "############### FABRIC-CA SAMPLES TEST ########################"
    echo "###############################################################"
    cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples/fabric-ca || exit
    ./start.sh && ./stop.sh
fi
