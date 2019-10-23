#!/bin/bash

SHELL_DIR=$(dirname $0)
CONFIG=${HOME}/.valve/valve-ctl
touch ${CONFIG} && . ${CONFIG}
# SHELL_DIR=${0}
# MYNAME=${0##*/}

#OS_NAME="$(uname | awk '{print tolower($0)}')"

# namespace
NAMESPACE="${NAMESPACE:-development}"

if [ "${OS_NAME}" == "darwin" ]; then
  command -v fzf > /dev/null && FZF=true
else
  FZF=""
fi

command -v tput > /dev/null && TPUT=true

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    echo
    if [ "${2}" == "" ]; then
        if [ "${TPUT}" != "" ]; then
            read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
        else
            read -p "$1" ANSWER
        fi
    else
        if [ "${TPUT}" != "" ]; then
            read -s -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
        else
            read -s -p "$1" ANSWER
        fi
        echo
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

_select_one() {
    OPT=$1

    SELECTED=

    CNT=$(cat ${LIST} | wc -l | xargs)
    if [ "x${CNT}" == "x0" ]; then
        return
    fi

    if [ "${OPT}" != "" ] && [ "x${CNT}" == "x1" ]; then
        SELECTED="$(cat ${LIST} | xargs)"
    else
        if [ "${FZF}" != "" ]; then
            SELECTED=$(cat ${LIST} | fzf --reverse --no-mouse --height=15 --bind=left:page-up,right:page-down)
        else
            echo

            IDX=0
            while read VAL; do
                IDX=$(( ${IDX} + 1 ))
                printf "%3s. %s\n" "${IDX}" "${VAL}"
            done < ${LIST}

            if [ "${CNT}" != "1" ]; then
                CNT="1-${CNT}"
            fi

            _read "Please select one. (${CNT}) : "

            if [ -z ${ANSWER} ]; then
                return
            fi
            TEST='^[0-9]+$'
            if ! [[ ${ANSWER} =~ ${TEST} ]]; then
                return
            fi
            SELECTED=$(sed -n ${ANSWER}p ${LIST})
        fi
    fi
}

_config_save() {
    FIND_CNT=$(cat ${CONFIG} | grep REGISTRY= | wc -l | xargs)
    if [ ${FIND_CNT} -eq 0 ]; then
        echo "# valve config" > ${CONFIG}
        echo "REGISTRY=${REGISTRY:-docker-registry.127.0.0.1.nip.io:30500}" >> ${CONFIG}
        echo "CHARTMUSEUM=${CHARTMUSEUM:-chartmuseum-devops.coruscant.opsnow.com}" >> ${CONFIG}
        echo "USERNAME=${USERNAME}" >> ${CONFIG}
    else
        _success "CONFIG Set"
    fi
}

_debug_mode() {
    if [ ${DEBUG_MODE} ]; then
        if [ $VERBOSE -ge 3 ]; then     # -vvv
            echo -e "\e[1;33m+ ${FUNCNAME[1]}\e[0m"
            set -x
        else                            # -v | --verbose
            echo -e "\e[1;33m+ ${FUNCNAME[1]}\e[0m"
        fi
    fi
}

_cmd_list() {
    # using object
    ls -p ${ROOT_CORE_DIR} | grep -e / | grep -v draft | grep -v '_' | awk -F/ '{print $1}'

    # Print commands in hidden object
    if ! find ${ROOT_CORE_DIR} -maxdepth 0 -empty | read; then
        find ${ROOT_CORE_DIR}  | grep -e / | grep -v draft | grep -E '_' | awk -F/ '{print $7}' | grep -e '.' | grep -v '\.'
    fi
}