#!/bin/bash

NB_CORES=`cat /proc/cpuinfo | grep processor | wc -l`

if [ $# -ne 1 ]
then
    echo "[USAGE] ./repo_init.sh <aosp_workspace>"
    exit 1
fi

AOSP_WORKSPACE=$1
AOSP_TAG="android-8.0.0_r30"
LOCAL_MANIFESTS_BRANCH="master"

# Initialize the AOSP tree
mkdir -p $AOSP_WORKSPACE
cd $AOSP_WORKSPACE
~/bin/repo init -u https://android.googlesource.com/platform/manifest.git -b $AOSP_TAG

# Add local_manifests
cd .repo
git clone https://github.com/abioteau/local_manifests
cd local_manifests
git checkout $LOCAL_MANIFESTS_BRANCH
cd ../..

# Download source code
~/bin/repo sync -j $NB_CORES

# Apply AOSP patches
./repo_update.sh

