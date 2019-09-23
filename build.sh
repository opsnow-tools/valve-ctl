#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1:-$CIRCLE_JOB}

RUN_PATH=${2:-$SHELL_DIR}

USERNAME=${CIRCLE_PROJECT_USERNAME:-opsnow-tools}
REPONAME=${CIRCLE_PROJECT_REPONAME:-valve-ctl}

BRANCH=${CIRCLE_BRANCH:-master}

PR_NUM=${CIRCLE_PR_NUMBER}
PR_URL=${CIRCLE_PULL_REQUEST}

################################################################################

# command -v tput > /dev/null && TPUT=true
TPUT=

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    echo
    _echo "# $@" 4
}

_command() {
    echo
    _echo "$ $@" 3
}

_success() {
    echo
    _echo "+ $@" 2
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    exit 1
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

_prepare() {
    # target
    mkdir -p ${RUN_PATH}/target/charts
    mkdir -p ${RUN_PATH}/target/publish
    mkdir -p ${RUN_PATH}/target/release

    # 755
    find ./** | grep [.]sh | xargs chmod 755
}

_package() {
    if [ ! -f ${SHELL_DIR}/target/VERSION ]; then
        _error
    fi

    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)
    _result "VERSION=${VERSION}"

    # target/
    cp -rf ${RUN_PATH}/builder.sh ${RUN_PATH}/target/publish/builder
    cp -rf ${RUN_PATH}/install.sh ${RUN_PATH}/target/publish/install
    cp -rf ${RUN_PATH}/slack.sh   ${RUN_PATH}/target/publish/slack
    cp -rf ${RUN_PATH}/tools.sh   ${RUN_PATH}/target/publish/tools

    # release
    cp -rf ${RUN_PATH}/valve.sh ${RUN_PATH}/target/release/valve

    # replace
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${RUN_PATH}/target/release/valve

    # release draft.tar.gz
    pushd ${RUN_PATH}/draft
    tar -czf ../target/release/draft.tar.gz *
    popd

    # target/charts/
    cp -rf ${RUN_PATH}/charts/* ${RUN_PATH}/target/charts/
}

################################################################################

_prepare

_package
