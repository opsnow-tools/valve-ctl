#!/bin/bash

command -v tput > /dev/null && TPUT=true

CONFIG=${HOME}/.valve/valve-ctl
CONFIG_DIR=${HOME}/.valve
mkdir -p $CONFIG_DIR
touch ${CONFIG} && . ${CONFIG}

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

# getopt
GETOPT=$(getopt 2>&1 | head -1 | xargs)
if [ "${GETOPT}" == "--" ]; then
    brew reinstall gnu-getopt
    brew link --force gnu-getopt
fi

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
OS_NAME="$(uname | awk '{print tolower($0)}')"

if [ "${OS_NAME}" == "linux" ]; then
    if [[ ! "$PATH" =~ "${HOME}/.local/bin" ]]; then
        echo "PATH=${HOME}/.local/bin:$PATH" >> ~/.bashrc
        _result "Finished. Restart your shell or reload config file"
        _result "          source ~/.bashrc # bash"
    fi
fi

# if dev mode exists(check symbolic link)
# LIB_DIR=$HOME/.local/share/valve
# if [ -L ${LIB_DIR} ]; then
#     if [ -e ${LIB_DIR} ]; then
#         _result "check link finish"
#         _result "Install start"
#     else
#         _error "broken link..."
#     fi
# else
#     _result "Install start"
# fi
_result "Install start..."
sleep 1

# install template
if [ -d ${CONFIG_DIR}/repo/valve ]; then
    pushd ${CONFIG_DIR}/repo/valve > /dev/null
    git pull > /dev/null 2>&1
    if [ $? -eq 128 ]; then
        _error "Update fail... Contact with SRE Team."
    fi
    popd > /dev/null
else
    mkdir -p ${CONFIG_DIR}/repo
    pushd ${CONFIG_DIR}/repo > /dev/null
    git clone https://github.com/opsnow-tools/valve-template.git valve > /dev/null 2>&1
    popd > /dev/null
fi

# Set LIB_DIR/BIN_DIR
if [ ${VERSION} == "dev" ]; then
    if [ "${OS_NAME}" == "darwin" ]; then
        LIB_DIR=/usr/local/share/valve
        BIN_DIR=/usr/local/bin
    elif [ "${OS_NAME}" == "linux" ]; then        
        BIN_DIR=$HOME/.local/bin
        LIB_DIR=$HOME/.local/share/valve
    else
        BIN_DIR=$HOME/bin
        LIB_DIR=$HOME/.local/share/valve
    fi
    mkdir -p ${BIN_DIR}
    mkdir -p ${LIB_DIR}

    # delete old version files
    rm -rf ${LIB_DIR}
    rm -f ${BIN_DIR}/${NAME}

    pushd ${PWD} > /dev/null
    if [ -f src/valve.sh ]; then
        VALVE_HOME=${PWD}/src
        ln -s ${VALVE_HOME} ${LIB_DIR}
        chmod -R +x ${LIB_DIR}
        ln -s ${PWD}/src/valve.sh ${BIN_DIR}/${NAME}
    else
        _error "There is no valve-ctl home. git clone valve-ctl your fork version"
    fi
    popd > /dev/null
else
    if [ "${OS_NAME}" == "darwin" ]; then
        BIN_DIR=/usr/local/bin
        LIB_DIR=/usr/local/share/valve
    elif [ "${OS_NAME}" == "linux" ]; then
        BIN_DIR=$HOME/.local/bin
        LIB_DIR=$HOME/.local/share/valve
    else
        BIN_DIR=$HOME/bin
        LIB_DIR=$HOME/.local/share/valve
    fi
    
    # delete old version files
    rm -rf ${LIB_DIR}
    rm -f ${BIN_DIR}/${NAME}

    mkdir -p ${LIB_DIR}
    mkdir -p ${BIN_DIR}

    

    # download new version files
    pushd ${LIB_DIR} > /dev/null
    curl -sL https://github.com/${USERNAME}/${REPONAME}/releases/download/${VERSION}/${NAME}.tar.gz | tar xz
    popd > /dev/null
    ln -s ${LIB_DIR}/${NAME}.sh ${BIN_DIR}/${NAME}
fi
