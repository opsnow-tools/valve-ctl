#!/bin/bash

SHELL_DIR=$(dirname $0)
CONFIG=${HOME}/.valve/valve-ctl
CONFIG_DIR=${HOME}/.valve
. ${CONFIG}
LOCAL_DIR=$(echo $PWD | awk -F'/' '{print $NF}')

if [ -f ${CONFIG} ]; then
    CHARTMUSEUM=$(cat ${CONFIG} | grep CHARTMUSEUM | awk -F'=' '{print $NF}')
    REGISTRY=$(cat ${CONFIG} | grep REGISTRY | awk -F'=' '{print $NF}')
fi

export THIS_REPO="opsnow-tools"
export THIS_NAME="valve-ctl"
# SHELL_DIR=${0}
# MYNAME=${0##*/}

OS_NAME="$(uname | awk '{print tolower($0)}')"

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

check_exit_code(){
    rcs=${PIPESTATUS[*]}
    rc=0
    for i in ${rcs}
        do
            rc=$(($i > $rc ? $i : $rc))
        done

    if [ $rc != 0 ]; then
        last_command=$@
        _warning "'$last_command' exit with $rc"
    fi

    return $rc
}

command_chk_exitcode(){
    echo
    _echo "$ $*" 3

    eval $*
    
    check_exit_code $*    
}

command_n_break(){
    command_chk_exitcode $*
    if [ $? != 0 ]; then
        exit $?
    fi
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

_warning_noreport() {
    echo
    _echo "- $@" 1
}

_warning() {
    echo
    _echo "- $@" 1
    _send_sentry 'warning' $@
}

_error() {
    echo
    _echo "- $@" 1
    _send_sentry 'error' $@
    exit 1
}

_error_noreport() {
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
    if [ -f ${CONFIG} ]; then
        FIND_CNT=$(cat ${CONFIG} | grep REGISTRY= | wc -l | xargs)
        if [ ${FIND_CNT} -eq 0 ]; then
            echo "# valve config" > ${CONFIG}
            echo "REGISTRY=${REGISTRY:-docker-registry.127.0.0.1.nip.io:30500}" >> ${CONFIG}
            echo "CHARTMUSEUM=${CHARTMUSEUM:-chartmuseum-devops.coruscant.opsnow.com}" >> ${CONFIG}
            echo "USERNAME=${USERNAME}" >> ${CONFIG}
        else
            _result "CONFIG Set"
        fi
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
        find ${ROOT_CORE_DIR}  | grep -E '_' | awk -F/ '{print $NF}' | grep -v '_' | grep -e '.' | grep -v '\.'
    fi
}


export OS_NAME="$(uname | awk '{print tolower($0)}')"
export PKG_MNG=

LINUX_DIST="$(uname -a)"

if [ "${OS_NAME}" == "linux" ]; then
    if [ "$(command -v yum)" != "" ]; then
        PKG_MNG="yum"
    elif [ "$(command -v apt)" != "" ]; then
        PKG_MNG="apt"
    fi
elif [ "${OS_NAME}" == "darwin" ]; then
    PKG_MNG="brew"
elif [[ "${OS_NAME}" =~ "ming" ]]; then
    PKG_MNG="windows"
fi

if [ "${PKG_MNG}" == "" ]; then
    _error "Not supported package manager. [${OS_NAME}:${OS_NAME}:${LINUX_DIST}]"
fi

# brew for mac
if [ "${PKG_MNG}" == "brew" ]; then
    _command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# for ubuntu
if [ "${PKG_MNG}" == "apt" ]; then
    export LC_ALL=C
fi

_send_sentry() {
    msg=
    args=("$@")
    for (( c=1; c<$#; c++ ))
    do
        msg+=" ${args[$c]}"
    done

    sentry-cli send-event -m "${msg}" -l ${args[0]}
}

_install_sentry() {
    #check sentry-cli
    if [ "$(command -v sentry-cli)" == "" ]; then
        if [ "${PKG_MNG}" == "brew" ]; then
            curl -sL https://sentry.io/get-cli/ | bash
        elif [ "${PKG_MNG}" == "apt" ]; then
            curl -sL https://sentry.io/get-cli/ | bash
        elif [ "${PKG_MNG}" == "yum" ]; then
            curl -sL https://sentry.io/get-cli/ | bash
        elif [ "${PKG_MNG}" == "choco" ]; then
            curl -sL https://sentry.io/get-cli/ | bash
        fi
    fi

    SENTRY_VERSION=$(sentry-cli --version | cut -d' ' -f2)
    _echo "sentry version check : ${SENTRY_VERSION}"
}
