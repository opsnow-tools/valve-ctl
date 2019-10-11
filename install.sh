#!/bin/bash

command -v tput > /dev/null && TPUT=true

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    _echo "# $@" 4
}

_command() {
    _echo "$ $@" 3
}

_success() {
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo "- $@" 1
    exit 1
}

################################################################################

USERNAME="opsnow-tools"
REPONAME="valve-ctl"

NAME="valve"

VERSION=${1}
_command "INPUT Version : ${VERSION}"

if [ -z ${VERSION} ]; then
    VERSION=$(curl -s https://api.github.com/repos/${USERNAME}/${REPONAME}/releases/latest | grep tag_name | cut -d'"' -f4)
    _command "github Version : ${VERSION}"

    if [ -z ${VERSION} ]; then
        VERSION=$(curl -sL repo.opsnow.io/${REPONAME}/VERSION | xargs)
        _command "repo Version : ${VERSION}"
    fi
fi

_result "version: ${VERSION}"

if [ -z ${VERSION} ]; then
    _error
fi

# copy
COPY_PATH=/usr/local/bin
DIST_DIR=/usr/local/share

if [ ! -z $HOME ]; then
    COUNT=$(echo "$PATH" | grep "$HOME/.local/bin" | wc -l | xargs)
    if [ "x${COUNT}" != "x0" ]; then    # For Linux
        COPY_PATH=$HOME/.local/bin
    else
        COUNT=$(echo "$PATH" | grep "$HOME/bin" | wc -l | xargs)
        if [ "x${COUNT}" != "x0" ]; then    # For Window
            DIST_DIR=$HOME/share
            COPY_PATH=$HOME/bin
            mkdir -p ${DIST_DIR}
            mkdir -p ${COPY_PATH}
        fi
    fi
fi

# rm DIST_DIR/*
rm -rf ${DIST_DIR}/${NAME}-*

# dist
DIST=${DIST_DIR}/${NAME}.sh

# download
pushd ${DIST_DIR} > /dev/null
curl -sL https://github.com/${USERNAME}/${REPONAME}/releases/download/${VERSION}/${NAME}.tar.gz | tar xz
popd > /dev/null

rm -f ${COPY_PATH}/${NAME}
ln -s ${DIST} ${COPY_PATH}/${NAME}