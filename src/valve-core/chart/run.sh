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

    list                    Chartmuseum에 배포된 차트를 목록으로 보여줍니다.
    version                 Chartmuseum에 배포된 차트의 버전을 보여줍니다.
    tag                     Chartmuseum에 배포된 차트의 태그를 보여주고, stable 태그를 추가/제거 할 수 있습니다.

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
        list)
            CMD=list
            ;;
        version)
            CMD=version
            ;;
        tag)
            CMD=tag
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
        _error_noreport "No params: $1, $CMD"
    fi

    # RUN plugin command
    shift
    $PLUGINS_DIR/${CMD} $*

}


_run $@