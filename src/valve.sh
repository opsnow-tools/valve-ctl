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
    help                    현재 화면을 보여줍니다.

    [valve-ctl tool 관리]
    update                  valve 를 최신버전으로 업데이트 합니다.
    version                 valve 버전을 확인 합니다.
    config                  저장된 설정을 조회 합니다.
    toolbox                 Local Kubernetes 환경을 구성하기 위한 툴 설치 및 환경 구성을 합니다.

    [valve-ctl 개발자 도구]
    search                  프로젝트 배포에 필요한 템플릿 리스트를 조회합니다.
    fetch                   프로젝트 배포에 필요한 템플릿를 개발 소스에 세팅(설치)합니다.
    on                      프로젝트를 Local Kubernetes에 배포합니다.
    off                     배포한 프로젝트를 삭제합니다.

    chart                   외부 프로젝트의 차트 릴리즈 목록을 확인하고 stable 버전을 관리합니다.
    repo                    외부 프로젝트 템플릿 레파지토리를 등록합니다.

    get                     배포한 프로젝트에 대한 정보를 확인합니다.
    ssh                     배포한 리소스의 pod에 ssh접속을 합니다.
    top                     배포한 리소스의 CPU, Memory 사용량을 조회합니다.
    log                     배포한 리소스의 로그를 조회합니다.

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
# Define short command
_set_cmd() {
    case $CMD in
        help)
            _help
            _success
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

_v1_help() {
cat << EOF
V1: (아래 기능들은 현재 사용가능 합니다. 곧 deprecated 예정입니다.)
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

EOF
}