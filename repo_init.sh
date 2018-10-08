#!/bin/bash

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

relpath () {
    [ $# -ge 1 ] && [ $# -le 2 ] || return 1
    current="${2:+"$1"}"
    target="${2:-"$1"}"
    if [[ "$target" = "http"* ]] || [[ "$current" = "http"* ]]; then
        echo "$target"
        return 0
    fi
    [ "$target" != . ] || target=/
    target="/${target##/}"
    [ "$current" != . ] || current=/
    current="${current:="/"}"
    current="/${current##/}"
    appendix="${target##/}"
    relative=''
    while appendix="${target#"$current"/}"
        [ "$current" != '/' ] && [ "$appendix" = "$target" ]; do
        if [ "$current" = "$appendix" ]; then
            relative="${relative:-.}"
            echo "${relative#/}"
            return 0
        fi
        current="${current%/*}"
        relative="$relative${relative:+/}.."
    done
    relative="$relative${relative:+${appendix:+/}}${appendix#/}"
    echo "$relative"
}

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
GITHUB_MIRROR_REL_URL=$(relpath $AOSP_MIRROR_URL/platform $GITHUB_MIRROR_URL)
GIT_BRANCH=$5

AOSP_TAG="android-9.0.0_r10"
LOCAL_MANIFESTS_BRANCH=$AOSP_TAG

# Initialize the AOSP tree
mkdir -p $AOSP_WORKSPACE
pushd $AOSP_WORKSPACE
~/bin/repo init -u $AOSP_MIRROR_URL/platform/manifest.git --repo-url $REPO_MIRROR_URL/git-repo.git -b $AOSP_TAG

# Add local_manifests
git clone $GITHUB_MIRROR_URL/abioteau/local_manifests.git .repo/local_manifests
pushd $AOSP_WORKSPACE/.repo/local_manifests
git checkout $LOCAL_MANIFESTS_BRANCH
sed -i "s/fetch=\".*:\/\/github.com\/\(.*\)\"/fetch=\"$(echo $GITHUB_MIRROR_REL_URL | sed 's/\//\\\//g')\/\1\"/" *.xml
popd

# Download source code
~/bin/repo sync -j $NB_CORES

# Apply AOSP patches
~/bin/repo start $GIT_BRANCH --all
./repo_update.sh
~/bin/repo prune

popd
