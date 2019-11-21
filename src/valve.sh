#!/bin/bash

######## variables
export OS_NAME="$(uname | awk '{print tolower($0)}')"

if [ "${OS_NAME}" == "darwin" ]; then
    readonly ROOT_SHELL_DIR=$(dirname "$(readlink "$0")")
else
    readonly ROOT_SHELL_DIR=$HOME/.local/share/valve
fi

export readonly ROOT_SHELL_DIR
export readonly ROOT_PLUGINS_DIR=$ROOT_SHELL_DIR/valve-plugins
export readonly ROOT_CORE_DIR=$ROOT_SHELL_DIR/valve-core
readonly PLUGIN_LIST=($(ls $ROOT_PLUGINS_DIR))
readonly CORE_LIST=($(ls $ROOT_CORE_DIR))

export THIS_VERSION="v0.0.0"

####### common functions
source $ROOT_SHELL_DIR/common.sh

################################################################################
# help message
_help() {
    #figlet "valve ctl 2"
cat << 'EOF'
================================================================================
            _                  _   _   ____
__   ____ _| |_   _____    ___| |_| | |___ \
\ \ / / _` | \ \ / / _ \  / __| __| |   __) |
 \ V / (_| | |\ V /  __/ | (__| |_| |  / __/
  \_/ \__,_|_| \_/ \___|  \___|\__|_| |_____|
================================================================================
EOF

cat <<EOF
Version : ${THIS_VERSION}
Usage: `basename $0` {Command} params..

Commands:
V2:
    h, help                 현재 화면을 보여줍니다.

    u, update               valve 를 최신버전으로 업데이트 합니다.
    v, version              valve 버전을 확인 합니다.

    V, valve                명시적으로 기존 valve-ctl 기능을 사용합니다. 생략할 수 있습니다.

V1: (아래 기능들은 현재 사용가능 합니다.)
    c, config               저장된 설정을 조회 합니다.

    i, init                 초기화를 합니다. Kubernetes 에 필요한 툴을 설치 합니다.
        -f, --force         가능하면 재설치 합니다.
        -d, --delete        기존 배포를 삭제 하고, 다음 작업을 수행합니다.

    g, gen                  프로젝트 배포에 필요한 패키지를 설치 합니다.
        -d, --delete        기존 패키지를 삭제 하고, 다음 작업을 수행합니다.

    up                   프로젝트를 Local Kubernetes 에 배포 합니다.
        -d, --delete        기존 배포를 삭제 하고, 다음 작업을 수행합니다.
        -r, --remote        Remote 프로젝트를 Local Kubernetes 에 배포 합니다.

    r, remote               Remote 프로젝트를 Local Kubernetes 에 배포 합니다.
        -v, --version=      프로젝트 버전을 알고 있을 경우 입력합니다.

    a, all                  배포된 리소스의 전체 list 를 조회 합니다.

    l, ls, list             배포된 리소스의 list 를 조회 합니다.
    d, desc                 배포된 리소스의 describe 를 조회 합니다.
    hpa                     배포된 리소스의 Horizontal Pod Autoscaler 를 조회 합니다.
    s, ssh                  배포된 리소스의 Pod 에 ssh 접속을 시도 합니다.
    log, logs               배포한 리소스의 logs 를 조회 합니다.
        -n, --namespace=    지정된 namespace 를 조회 합니다.

    rm, remove              배포한 프로젝트를 삭제 합니다.

    clean                   저장된 설정을 모두 삭제 합니다.
        -d, --delete        docker 이미지도 모두 삭제 합니다.

    chart                   Helm 차트와 차트 릴리즈 목록을 확인하고 stable 버전을 생성, 삭제 합니다.
        list                차트 목록을 조회합니다.
        release             차트 릴리즈를 관리합니다.

    tools                   개발에 필요한 툴을 설치 합니다. (MacOS, Ubuntu 만 지원)

Check command lists:
-----------------------------------
EOF
_cmd_list   # Print using object and hidden object command in common.sh

cat << EOF
$(ls -p ${ROOT_PLUGINS_DIR} | grep -e / | grep -v draft | awk -F/ '{print $1}')
-----------------------------------
================================================================================
EOF

}

###################################################################################

_update() {
    _echo "# version: ${THIS_VERSION}" 3
    curl -sL repo.opsnow.io/${THIS_NAME}/install | bash -s ${NAME}
    exit 0
}

_version() {
    _command "kubectl version"
    kubectl version

    _command "helm version"
    helm version

    _command "draft version"
    draft version

    _command "valve version"
    _echo "${THIS_VERSION}"
}

###################################################################################
# Define short command
_set_cmd() {
    case $CMD in
        h|help)
            _help
            _success
            ;;
        v)
            _version
            _success
            ;;
        u)
            _update
            _success
            ;;
        t)
            CMD=template
            ;;
        fetch)
            CMD=_template
            H_CMD=fetch
            ;;
        on)
            CMD=_template
            H_CMD=on
            ;;
        off)
            CMD=_template
            H_CMD=off
            ;;
        search)
            CMD=_template
            H_CMD=search
            ;;
        ssh)
            CMD=_template
            H_CMD=ssh
            ;;
        log)
            CMD=_template
            H_CMD=log
            ;;
        top)
            CMD=_template
            H_CMD=top
            ;;
        get)
            CMD=_template
            H_CMD=get
            ;;
        update)
            CMD=_valve
            H_CMD=update
            ;;
        version)
            CMD=_valve
            H_CMD=version
            ;;
        config)
            CMD=_valve
            H_CMD=config
            ;;
        e)
            CMD=example
            ;;
        tb)
            CMD=toolbox
            ;;
        V)
            CMD=valve
            ;;
    esac
}

# main loop
_run() {
    # check first param
    if [ ! -z $1 ]; then
        CMD=$1
    else
        _help
        _error "No input"
    fi

    # replace short cmd to long cmd
    _set_cmd

    ### Use another script, if exist ###
    # check if exist plugin
    if [ ! -d $ROOT_PLUGINS_DIR/$CMD -a ! -d $ROOT_CORE_DIR/$CMD ]; then
        CMD="valve"
        $ROOT_PLUGINS_DIR/${CMD} $*
    else
        shift
        # RUN plugin command
        if [ -d $ROOT_PLUGINS_DIR/$CMD ]; then
            # _command "$ROOT_PLUGINS_DIR/${CMD} $*"
            $ROOT_PLUGINS_DIR/${CMD}/run.sh $*
        elif [ -d $ROOT_CORE_DIR/$CMD ]; then
            if [ ! -z $H_CMD ]; then
                $ROOT_CORE_DIR/${CMD}/run.sh $H_CMD $*
            else
                $ROOT_CORE_DIR/${CMD}/run.sh $*
            fi
        fi
    fi

    
}

_run $@

