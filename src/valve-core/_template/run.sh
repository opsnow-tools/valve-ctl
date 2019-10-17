#!/bin/bash

CUR_DIR=${0%/*}
CUR_OBJECT=`echo $CUR_DIR | cut -d "/" -f6`
readonly PLUGINS_DIR=${CUR_DIR}

####### common functions
source ${ROOT_SHELL_DIR}/common.sh

_help() {
    cat <<EOF
================================================================================
Usage: valve ${CUR_OBJECT} {Params}

Params:
    h, help                 현재 화면을 보여줍니다.

    f, fetch                템플릿을 설치합니다.

================================================================================
EOF
}

# Define short command
_set_cmd() {
    case $CMD in
# 2 point. _set_cmd function 내 case 추가
        h)
            CMD=help
            ;;
        f|fetch)
            CMD=fetch
            ;;
    esac
}

_run() {
    # check first param
    if [ -z $1 ]; then
        _help
        _success
    elif [ $1 == "h" -o $1 == "help" ]; then
        _help
        _success
    else
        CMD=$1
        _set_cmd
    fi

    ### Use another script, if exist ###
    # check if exist plugin
    if [ ! -f $PLUGINS_DIR/$CMD ]; then
        _help
        _error "No params: $1, $CMD"
    fi

    # RUN plugin command
    shift
    $PLUGINS_DIR/${CMD} $*

}


_run $@