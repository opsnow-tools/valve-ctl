#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1}

USERNAME=${CIRCLE_PROJECT_USERNAME:-opsnow-tools}
REPONAME=${CIRCLE_PROJECT_REPONAME:-valve-ctl}

################################################################################

# command -v tput > /dev/null || TPUT=false
TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
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

_prepare() {
    # target
    rm -rf ${SHELL_DIR}/target
    mkdir -p ${SHELL_DIR}/target/dist
    mkdir -p ${SHELL_DIR}/target/charts

    # 755
    find ./** | grep [.]sh | xargs chmod 755
}

_get_version() {
    # previous versions
    VERSION=$(curl -s https://api.github.com/repos/${USERNAME}/${REPONAME}/releases/latest | grep tag_name | cut -d'"' -f4 | xargs)

    if [ ! -f ${SHELL_DIR}/VERSION ]; then
        echo "v0.0.0" > ${SHELL_DIR}/VERSION
    fi

    if [ -z ${VERSION} ]; then
        VERSION=$(cat ${SHELL_DIR}/VERSION | xargs)
    fi
}

_gen_version() {
    _get_version

    # release version
    MAJOR=$(cat ${SHELL_DIR}/VERSION | xargs | cut -d'.' -f1)
    MINOR=$(cat ${SHELL_DIR}/VERSION | xargs | cut -d'.' -f2)

    LATEST_MAJOR=$(echo ${VERSION} | cut -d'.' -f1)
    LATEST_MINOR=$(echo ${VERSION} | cut -d'.' -f2)

    if [ "${MAJOR}" != "${LATEST_MAJOR}" ] || [ "${MINOR}" != "${LATEST_MINOR}" ]; then
        VERSION=$(cat ${SHELL_DIR}/VERSION | xargs)
    fi

    # add build version
    VERSION=$(echo ${VERSION} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')

    echo "${VERSION}" > ${SHELL_DIR}/target/VERSION
    echo "${VERSION}" > ${SHELL_DIR}/versions/VERSION
}

_package() {
    # target/
    cp -rf ${SHELL_DIR}/install.sh ${SHELL_DIR}/target/install
    cp -rf ${SHELL_DIR}/slack.sh   ${SHELL_DIR}/target/slack
    cp -rf ${SHELL_DIR}/tools.sh   ${SHELL_DIR}/target/tools

    # target/dist/
    cp -rf ${SHELL_DIR}/valve.sh ${SHELL_DIR}/target/dist/valve

    # version
    _gen_version

    _result "VERSION=${VERSION}"

    # replace version
    if [ "${OS_NAME}" == "linux" ]; then
        sed -i -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" ${SHELL_DIR}/target/dist/valve
    elif [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" ${SHELL_DIR}/target/dist/valve
    fi

    # target/dist/draft.tar.gz
    pushd ${SHELL_DIR}/draft
    tar -czf ../target/dist/draft.tar.gz *
    popd

    # target/charts/
    cp -rf ${SHELL_DIR}/charts/* ${SHELL_DIR}/target/charts/
}

_publish() {
    aws s3 sync ${SHELL_DIR}/target/ s3://repo.opsnow.io/${REPONAME}/ --acl public-read
}

_release() {
    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)

    _result "VERSION=${VERSION}"

    _command "go get github.com/tcnksm/ghr"
    go get github.com/tcnksm/ghr

    _command "ghr ${VERSION} ${SHELL_DIR}/versions/"
    ghr -t ${GITHUB_TOKEN} \
        -u ${USERNAME} \
        -r ${REPONAME} \
        -c ${CIRCLE_SHA1} \
        -delete \
        ${VERSION} ${SHELL_DIR}/versions/
}

_slack() {
    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)

    _result "VERSION=${VERSION}"

    FOOTER="<https://github.com/${USERNAME}/${REPONAME}|${USERNAME}/${REPONAME}>"

    ${SHELL_DIR}/target/slack --token="${SLACK_TOKEN}" --channel="tools" \
        --emoji=":construction_worker:" --username="valve" \
        --footer="${FOOTER}" --footer_icon="https://assets-cdn.github.com/favicon.ico" \
        --color="good" --title="${REPONAME} updated" "\`${VERSION}\`"
}

_prepare

case ${CMD} in
    package)
        _package
        ;;
    publish)
        _publish
        ;;
    release)
        _release
        ;;
    slack)
        _slack
        ;;
esac
