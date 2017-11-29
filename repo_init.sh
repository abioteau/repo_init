#!/bin/bash

NB_CORES=`cat /proc/cpuinfo | grep processor | wc -l`

if [ $# -ne 5 ]
then
    echo "[USAGE] ./repo_init.sh <aosp_workspace> <aosp_mirror_url> <repo_mirror_url> <github_mirror_url> <git_branch>"
    exit 1
fi

AOSP_WORKSPACE=$1
AOSP_MIRROR_URL=$2
REPO_MIRROR_URL=$3
GITHUB_MIRROR_URL=$4
GIT_BRANCH=$5

AOSP_TAG="android-7.1.1_r55"
LOCAL_MANIFESTS_BRANCH="n-mr1_3.10"

# Initialize the AOSP tree
mkdir -p $AOSP_WORKSPACE
cd $AOSP_WORKSPACE
~/bin/repo init -u $AOSP_MIRROR_URL/platform/manifest.git --repo-url $REPO_MIRROR_URL/git-repo.git -b $AOSP_TAG

# Add local_manifests
cd .repo
git clone $GITHUB_MIRROR_URL/abioteau/local_manifests
cd local_manifests
git checkout $LOCAL_MANIFESTS_BRANCH
cd ../..

# Download source code
~/bin/repo sync -j $NB_CORES

# Apply AOSP patches
~/bin/repo start $GIT_BRANCH --all
./repo_update.sh
~/bin/repo prune
