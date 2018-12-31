#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1:-${CIRCLE_JOB}}

USERNAME=${CIRCLE_PROJECT_USERNAME:-opsnow-tools}
REPONAME=${CIRCLE_PROJECT_REPONAME:-valve-ctl}

PR_NUM=${CIRCLE_PR_NUMBER}
PR_URL=${CIRCLE_PULL_REQUEST}

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
    mkdir -p ${SHELL_DIR}/target/dist
    mkdir -p ${SHELL_DIR}/target/charts

    # 755
    find ./** | grep [.]sh | xargs chmod 755
}

_get_version() {
    # latest versions
    VERSION=$(curl -s https://api.github.com/repos/${USERNAME}/${REPONAME}/releases/latest | grep tag_name | cut -d'"' -f4 | xargs)

    if [ -z ${VERSION} ]; then
        VERSION=$(curl -sL repo.opsnow.io/${REPONAME}/VERSION | xargs)
    fi

    if [ ! -f ${SHELL_DIR}/VERSION ]; then
        printf "v0.0.0" > ${SHELL_DIR}/VERSION
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

    _result "CIRCLE_BRANCH=${CIRCLE_BRANCH}"
    _result "PR_NUM=${PR_NUM}"
    _result "PR_URL=${PR_URL}"

    # version
    if [ "${CIRCLE_BRANCH}" == "master" ]; then
        VERSION=$(echo ${VERSION} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')
        printf "${VERSION}" > ${SHELL_DIR}/target/VERSION
    else
        if [ "${PR_NUM}" == "" ]; then
            if [ "${PR_URL}" != "" ]; then
                PR_NUM=$(echo $PR_URL | cut -d'/' -f7)
            else
                PR_NUM=${CIRCLE_BUILD_NUM}
            fi
        fi

        printf "${PR_NUM}" > ${SHELL_DIR}/target/PRE

        VERSION="${VERSION}-${PR_NUM}"
        printf "${VERSION}" > ${SHELL_DIR}/target/VERSION
    fi
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

    # replace
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

_s3_sync() {
    _command "aws s3 sync ${1} s3://${2}/ --acl public-read"
    aws s3 sync ${1} s3://${2}/ --acl public-read
}

_cf_reset() {
    CFID=$(aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id, DomainName: DomainName, OriginDomainName: Origins.Items[0].DomainName}[?contains(OriginDomainName, '${1}')] | [0]" | jq -r '.Id')
    if [ "${CFID}" != "" ]; then
        aws cloudfront create-invalidation --distribution-id ${CFID} --paths "/*"
    fi
}

_publish() {
    if [ ! -f ${SHELL_DIR}/target/VERSION ]; then
        _error
    fi
    if [ -f ${SHELL_DIR}/target/PRE ]; then
        return
    fi

    _s3_sync "${SHELL_DIR}/target/" "repo.opsnow.io/${REPONAME}"

    _cf_reset "repo.opsnow.io"
}

_release() {
    if [ ! -f ${SHELL_DIR}/target/VERSION ]; then
        _error
    fi
    if [ -f ${SHELL_DIR}/target/PRE ]; then
        GHR_PARAM="-delete -prerelease"
    else
        GHR_PARAM="-delete"
    fi

    # result
    ls -al ${SHELL_DIR}/target/
    ls -al ${SHELL_DIR}/target/dist/

    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)

    _result "VERSION=${VERSION}"

    _command "go get github.com/tcnksm/ghr"
    go get github.com/tcnksm/ghr

    _command "ghr ${VERSION} ${SHELL_DIR}/target/dist/"
    ghr -t ${GITHUB_TOKEN} \
        -u ${USERNAME} \
        -r ${REPONAME} \
        -c ${CIRCLE_SHA1} \
        ${GHR_PARAM} \
        ${VERSION} ${SHELL_DIR}/target/dist/
}

_slack() {
    if [ ! -f ${SHELL_DIR}/target/VERSION ]; then
        _error
    fi
    if [ -f ${SHELL_DIR}/target/PRE ]; then
        TITLE="${REPONAME} pull requested"
    else
        TITLE="${REPONAME} updated"
    fi

    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)

    _result "VERSION=${VERSION}"

    FOOTER="<https://github.com/${USERNAME}/${REPONAME}/releases/tag/${VERSION}|${USERNAME}/${REPONAME}>"

    ${SHELL_DIR}/target/slack --token="${SLACK_TOKEN}" --channel="tools" \
        --emoji=":construction_worker:" --username="valve" \
        --footer="${FOOTER}" --footer_icon="https://assets-cdn.github.com/favicon.ico" \
        --color="good" --title="${TITLE}" "\`${VERSION}\`"
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
