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
if [ ! -z $HOME ]; then
    COUNT=$(echo "$PATH" | grep "$HOME/.local/bin" | wc -l | xargs)
    if [ "x${COUNT}" == "x0" ]; then
        echo "PATH=$HOME/.local/bin:$PATH" >> $HOME/.bash_profile
    fi

    mkdir -p $HOME/.local/bin
    mv -f ${DIST} $HOME/.local/bin/${NAME}
else
    mv -f ${DIST} /usr/local/bin/${NAME}
fi

# done
_success "done."
