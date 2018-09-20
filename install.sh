#!/bin/bash

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
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

NAME="valve"

VERSION=$(curl -s https://api.github.com/repos/opsnow-tools/valve-ctl/releases/latest | grep tag_name | cut -d'"' -f4)

_result "version: ${VERSION}"

if [ -z ${VERSION} ]; then
    _error
fi

# dist
DIST=/tmp/${NAME}-${VERSION}
rm -rf ${DIST}

# download
curl -sL -o ${DIST} https://github.com/opsnow-tools/valve-ctl/releases/download/${VERSION}/valve
chmod +x ${DIST}

# copy
COPY_PATH=/usr/local/bin
if [ ! -z $HOME ]; then
    COUNT=$(echo "$PATH" | grep "$HOME/.local/bin" | wc -l | xargs)
    if [ "x${COUNT}" != "x0" ]; then
        COPY_PATH=$HOME/.local/bin
        mkdir -p ${COPY_PATH}
    fi
fi

mv -f ${DIST} ${COPY_PATH}/${NAME}

# done
_success "done."
