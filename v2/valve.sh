#!/bin/bash

######## variables
export OS_NAME="$(uname | awk '{print tolower($0)}')"

if [ "${OS_NAME}" == "darwin" ]; then
    readonly ROOT_SHELL_DIR=$(dirname "$(readlink "$0")")
else
    readonly ROOT_SHELL_DIR=$(dirname "$(readlink -f "$0")")
fi

export readonly ROOT_PLUGINS_DIR=$ROOT_SHELL_DIR/valve-plugins
readonly PLUGIN_LIST=($(ls $ROOT_PLUGINS_DIR))

THIS_REPO="opsnow-tools"
THIS_NAME="valve-ctl"
THIS_VERSION="v0.0.0"

####### common functions
source $ROOT_PLUGINS_DIR/common.sh

################################################################################
# help message
_help() {
    #figlet "valve ctl 2"
cat << 'EOF'
================================================================================
            _                  _   _   ____
__   ____ _| |_   _____    ___| |_| | |___ \
\ \ / / _` | \ \ / / _ \  / __| __| |   __) |
 \ V / (_| | |\ V /  __/ | (__| |_| |  / __/
  \_/ \__,_|_| \_/ \___|  \___|\__|_| |_____|
================================================================================
EOF

cat <<EOF
Version : ${THIS_VERSION}
Usage: `basename $0` {Command} params..

Commands:
    h, help                 현재 화면을 보여줍니다.
    v, version              현재 version 을 보여줍니다.
    u, update               최신 version 으로 업데이트 합니다.

    V, valve                명시적으로 기존 valve-ctl 기능을 사용합니다. 생략할 수 있습니다.

Check command lists:
-----------------------------------
$(ls -p ${ROOT_PLUGINS_DIR} | grep -v / | grep -v common.sh)
-----------------------------------
================================================================================
EOF

}

###################################################################################

_update() {
    _echo "# version: ${THIS_VERSION}" 3
    curl -sL repo.opsnow.io/${THIS_NAME}/install | bash -s ${NAME}
    exit 0
}

_version() {
    _command "kubectl version"
    kubectl version

    _command "helm version"
    helm version

    _command "draft version"
    draft version

    _command "valve version"
    _echo "${THIS_VERSION}"
}

###################################################################################
# Define short command
_set_cmd() {
    case $CMD in
        h|help)
            _help
            _success
            ;;
        v|version)
            _version
            _success
            ;;
        u|update)
            _update
            _success
            ;;
        t)
            CMD=template
            ;;
        f)
            CMD=fetch
            ;;
        tb)
            CMD=toolbox
            ;;
        V)
            CMD=valve
            ;;
    esac
}

# main loop
_run() {
    # check first param
    if [ ! -z $1 ]; then
        CMD=$1
    else
        _help
        _error "No input"
    fi

    # replace short cmd to long cmd
    _set_cmd

    # check if exist plugin
    ls $ROOT_PLUGINS_DIR/$CMD 2>/dev/null | grep -v common.sh
    if [ $? -gt 0 ]; then
        # RUN valve before version
        CMD="valve"
    else
        # shift params
        shift
    fi

    # RUN plugin command
    # _command "$ROOT_PLUGINS_DIR/${CMD} $*"
    command $ROOT_PLUGINS_DIR/${CMD} $*


}

_run $@

