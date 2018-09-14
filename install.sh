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

OS_NAME="$(uname | awk '{print tolower($0)}')"

VERSION=$(curl -s https://api.github.com/repos/opsnow-tools/valve-tee/releases/latest | grep tag_name | cut -d'"' -f4)

_result "version: ${VERSION}"

if [ -z ${VERSION} ]; then
    _error
fi

DIST=/tmp/valve-tee-${VERSION}
rm -rf ${DIST}

# download
curl -sL -o ${DIST} https://github.com/opsnow-tools/valve-tee/releases/download/${VERSION}/tee
chmod +x ${DIST}

if [ -d ~/.local/bin ]; then
    mv -f ${DIST} ~/.local/bin/tee
elif [ -d ~/bin ]; then
    mv -f ${DIST} ~/bin/tee
else
    mv -f ${DIST} /usr/local/bin/tee
fi

# done
_success "done."
