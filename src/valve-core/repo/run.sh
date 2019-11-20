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
    help                    현재 화면을 보여줍니다.

    list                    등록한 커스텀 템플릿 레파지토리 리스트를 보여줍니다.

    add                     구성할 커스텀 템플릿이 있는 레파지토리를 등록합니다.

    remove                  구성한 커스텀 템플릿 레파지토리를 삭제합니다.

    update                  특정 커스텀 템플릿 레파지토리를 업데이트 합니다.

================================================================================
EOF
}

# Define short command
_set_cmd() {
    case $CMD in
# 2 point. _set_cmd function 내 case 추가
        help)
            CMD=help
            ;;
        list)
            CMD=list
            ;;
        add)
            CMD=add
            ;;
        remove)
            CMD=remove
            ;;
        update)
            CMD=update
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