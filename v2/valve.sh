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

    v, valve                명시적으로 기존 valve-ctl 기능을 사용합니다. 생략할 수 있습니다.

Check command lists:
-----------------------------------
$(ls -p ${ROOT_PLUGINS_DIR} | grep -v / | grep -v common.sh)
-----------------------------------
================================================================================
EOF

}

# Define short command
_replace_cmd_short2long() {
    case $CMD in
        t)
            CMD=template
            ;;
        f)
            CMD=fetch
            ;;
        tb)
            CMD=toolbox
            ;;
        v)
            CMD=valve
            ;;
    esac
}

_run() {
    # check first param
    if [ ! -z $1 ]; then
        CMD=$1
    else
        _help
        _error "No input"
    fi

    # replace short cmd to long cmd
    _replace_cmd_short2long

    # check if exist plugin
    ls $ROOT_PLUGINS_DIR/$CMD > /dev/null 2>&1 | grep -v common.sh
    if [ $? -gt 0 ]; then
        # RUN valve before version
        CMD="valve"
    else
        # shift params
        shift
    fi

    # RUN plugin command
    _command "$ROOT_PLUGINS_DIR/${CMD} $*"
    command $ROOT_PLUGINS_DIR/${CMD} $*

}

_run $@

