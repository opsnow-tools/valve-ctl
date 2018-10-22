#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_REPO="valve-tools"
THIS_NAME="valve-ctl"
THIS_VERSION="v0.0.0"

SHELL_DIR=$(dirname $0)

CMD=$1
SUB=$2

NAME=
VERSION=
PACKAGE=

SECRET=
NAMESPACE=
CLUSTER=

BASE_DOMAIN=
REGISTRY=
CHARTMUSEUM=

REMOTE=

FORCE=
DELETE=

CONFIG=${HOME}/.valve-ctl
touch ${CONFIG} && . ${CONFIG}

################################################################################

for v in "$@"; do
    case ${v} in
    --this=*)
        THIS_VERSION="${v#*=}"
        shift
        ;;
    --name=*)
        NAME="${v#*=}"
        shift
        ;;
    --version=*)
        VERSION="${v#*=}"
        shift
        ;;
    --package=*)
        PACKAGE="${v#*=}"
        shift
        ;;
    --secret=*)
        SECRET="${v#*=}"
        shift
        ;;
    --namespace=*)
        NAMESPACE="${v#*=}"
        shift
        ;;
    --cluster=*)
        CLUSTER="${v#*=}"
        shift
        ;;
    --registry=*)
        REGISTRY="${v#*=}"
        shift
        ;;
    --chartmuseum=*)
        CHARTMUSEUM="${v#*=}"
        shift
        ;;
    --remote)
        REMOTE=true
        shift
        ;;
    --force)
        FORCE=true
        shift
        ;;
    --delete)
        DELETE=true
        shift
        ;;
    *)
        shift
        ;;
    esac
done

################################################################################

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    if [ -z ${TPUT} ]; then
        read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
    else
        read -p "$1" ANSWER
    fi
}

_result() {
    _echo
    _echo "# $@" 4
}

_command() {
    _echo
    _echo "$ $@" 3
}

_success() {
    _echo
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo
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

_usage() {
    #figlet valve ctl
cat <<EOF
================================================================================
             _                  _   _
 __   ____ _| |_   _____    ___| |_| |
 \ \ / / _' | \ \ / / _ \  / __| __| |
  \ V / (_| | |\ V /  __/ | (__| |_| |
   \_/ \__,_|_| \_/ \___|  \___|\__|_|  ${THIS_VERSION}
================================================================================
 Usage: valve {command} [args]

 Commands:
   c, config    저장된 설정을 보여줍니다.
   i, init      초기화를 합니다. Kubernetes 에 필요한 툴을 설치 합니다.
   u, up        프로젝트를 Local Kubernetes 에 배포 합니다.
   r, remote    Remote 프로젝트를 Local Kubernetes 에 배포 합니다.

   a, all       전체 리소스의 내역을 봅니다.
   l, ls, list  배포 내역을 보여줍니다.
   d, desc      배포된 리소스의 상세 내용을 봅니다.
   g, gen       프로젝트 배포에 필요한 패키지를 설치 합니다.
   log, logs    배포한 프로젝트의 로그를 봅니다.
   rm, remove   배포한 프로젝트를 삭제 합니다.

   clean        저장된 설정을 삭제 합니다. (docker 이미지도 모두 삭제)
   tools        개발에 필요한 툴을 설치 합니다. (MacOS, Ubuntu 만 지원)
   update       valve 를 최신버전으로 업데이트 합니다.
   v, version   valve 버전을 확인 합니다.

Arguments:
   --force      가능하면 재설치를 합니다.
   --delete     기본 배포를 삭제 하고, 다음 작업을 수행합니다.
   --remote
================================================================================
EOF
    _success
}

################################################################################

_run() {
    case ${CMD} in
        c|conf|config)
            _config
            ;;
        i|init)
            _init
            ;;
        g|gen)
            _gen
            ;;
        u|up)
            if [ -z ${REMOTE} ]; then
                _up
            else
                _remote
            fi
            ;;
        r|remote)
            _remote
            ;;
        a|all)
            _all
            ;;
        l|ls|list)
            _list
            ;;
        d|desc|describe)
            _describe
            ;;
        log|logs)
            _logs
            ;;
        rm|remove)
            _remove
            ;;
        clean)
            _clean
            ;;
        sample)
            _sample
            ;;
        tools)
            _tools
            ;;
        update)
            _update
            ;;
        v|version)
            _version
            ;;
        *)
            _usage
    esac
}

_tools() {
    curl -sL repo.opsnow.io/${THIS_NAME}/tools | bash
    exit 0
}

_update() {
    _echo "# version: ${THIS_VERSION}" 3
    curl -sL repo.opsnow.io/${THIS_NAME}/install | bash
    exit 0
}

_version() {
    _command "helm version --client"
    helm version --client

    _command "draft version"
    draft version

    _command "valve version"
    _echo "# version: ${THIS_VERSION}" 4
}

_waiting_pod() {
    _NS=${1}
    _NM=${2}
    SEC=${3:-30}

    TMP=/tmp/valve-pod-status

    _command "kubectl get pod -n ${_NS} | grep ${_NM}"

    IDX=0
    while [ 1 ]; do
        kubectl get pod -n ${_NS} | grep ${_NM} | head -1 > ${TMP}
        cat ${TMP}

        STATUS=$(cat /tmp/valve-pod-status | awk '{print $3}')

        if [ "${STATUS}" == "Running" ] && [ "${_NS}" != "development" ]; then
            READY=$(cat /tmp/valve-pod-status | awk '{print $2}' | cut -d'/' -f1)
        else
            READY="1"
        fi

        if [ "${STATUS}" == "Running" ] && [ "x${READY}" != "x0" ]; then
            break
        elif [ "${STATUS}" == "Error" ]; then
            _error "${STATUS}"
        elif [ "${STATUS}" == "CrashLoopBackOff" ]; then
            _error "${STATUS}"
        elif [ "x${IDX}" == "x${SEC}" ]; then
            _error "Timeout"
        fi

        IDX=$(( ${IDX} + 1 ))
        sleep 2
    done
}

_select_one() {
    echo

    IDX=0
    while read VAL; do
        IDX=$(( ${IDX} + 1 ))
        printf "%3s. %s\n" "${IDX}" "${VAL}";
    done < ${LIST}

    CNT=$(cat ${LIST} | wc -l | xargs)

    if [ "x${CNT}" == "x0" ]; then
        _error
    fi

    if [ "${CNT}" != "1" ]; then
        CNT="1-${CNT}"
    fi

    echo
    _read "Please select one. (${CNT}) : "

    SELECTED=
    if [ "${ANSWER}" == "" ]; then
        _error
    fi
    TEST='^[0-9]+$'
    if ! [[ ${ANSWER} =~ ${TEST} ]]; then
        _error
    fi
    SELECTED=$(sed -n ${ANSWER}p ${LIST})
    if [ -z ${SELECTED} ]; then
        _error
    fi
}

_config() {
    echo
    cat ${CONFIG}
}

_config_save() {
    echo "# valve config" > ${CONFIG}
    echo "SECRET=${SECRET}" >> ${CONFIG}
    echo "CLUSTER=${CLUSTER}" >> ${CONFIG}
    echo "BASE_DOMAIN=${BASE_DOMAIN}" >> ${CONFIG}
    echo "REGISTRY=${REGISTRY}" >> ${CONFIG}
    echo "CHARTMUSEUM=${CHARTMUSEUM}" >> ${CONFIG}
}

_init() {
    _helm_init
    _draft_init
}

_helm_init() {
    _command "helm init --upgrade"
    helm init --upgrade

    _command "helm repo update"
    helm repo update

    # waiting tiller
    _waiting_pod "kube-system" "tiller"

    # _command "helm version"
    # helm version

    if [ ! -z ${DELETE} ]; then
        _helm_delete "docker-registry"
        _helm_delete "metrics-server"
        _helm_delete "nginx-ingress"
    fi

    # namespace
    NAMESPACE="${NAMESPACE:-kube-system}"

    _helm_install "${NAMESPACE}" "docker-registry"
    _helm_install "${NAMESPACE}" "metrics-server"
    _helm_install "${NAMESPACE}" "nginx-ingress"

    _waiting_pod "${NAMESPACE}" "docker-registry"
    _waiting_pod "${NAMESPACE}" "nginx-ingress"
}

_helm_repo() {
    CNT=$(helm repo list | grep chartmuseum | wc -l | xargs)

    if [ "x${CNT}" == "x0" ] || [ ! -z ${FORCE} ]; then
        echo
        DEFAULT="${CHARTMUSEUM:-chartmuseum-devops.demo.opsnow.com}"
        _read "CHARTMUSEUM [${DEFAULT}] : "

        if [ -z ${ANSWER} ]; then
            CHARTMUSEUM="${DEFAULT}"
        else
            CHARTMUSEUM="${ANSWER}"
        fi
        if [ -z ${CHARTMUSEUM} ]; then
            _error
        fi

        _command "helm repo add chartmuseum https://${CHARTMUSEUM}"
        helm repo add chartmuseum https://${CHARTMUSEUM}

        _config_save
    fi

    _command "helm repo update"
    helm repo update
}

_helm_delete() {
    _NM=$1

    CNT=$(helm ls ${_NM} | wc -l | xargs)

    if [ "x${CNT}" != "x0" ]; then
        _command "helm delete ${_NM} --purge"
        helm delete ${_NM} --purge
    fi
}

_helm_install() {
    _NS=$1
    _NM=$2

    CNT=$(helm ls ${_NM} | wc -l | xargs)

    if [ "x${CNT}" == "x0" ] || [ ! -z ${FORCE} ]; then
        CHART=/tmp/${_NM}.yaml

        _get_yaml "charts/${_NM}" "${CHART}"

        CHART_VERSION=$(cat ${CHART} | grep chart-version | awk '{print $3}' | xargs)

        if [ -z ${CHART_VERSION} ] || [ "${CHART_VERSION}" == "latest" ]; then
            _command "helm upgrade --install ${_NM} stable/${_NM}"
            helm upgrade --install ${_NM} stable/${_NM} --namespace ${_NS} -f ${CHART}
        else
            _command "helm upgrade --install ${_NM} stable/${_NM} --version ${CHART_VERSION}"
            helm upgrade --install ${_NM} stable/${_NM} --namespace ${_NS} -f ${CHART} --version ${CHART_VERSION}
        fi
    fi
}

_draft_init() {
    _command "draft init"
    draft init

    # _command "draft version"
    # draft version

    draft config set disable-push-warning 1

    # curl -sL docker-registry.127.0.0.1.nip.io:30500/v2/_catalog | jq '.'
    REGISTRY="${REGISTRY:-docker-registry.127.0.0.1.nip.io:30500}"

    # registry
    if [ -z ${REGISTRY} ]; then
        _command "draft config unset registry"
        draft config unset registry
    else
        _command "draft config set registry ${REGISTRY}"
        draft config set registry ${REGISTRY}
    fi

    _config_save
}

_gen() {
    _result "draft package version: ${THIS_VERSION}"

    DIST=/tmp/valve-draft-${THIS_VERSION}
    LIST=/tmp/valve-draft-ls

    if [ "${THIS_VERSION}" == "v0.0.0" ]; then
        if [ ! -d ${SHELL_DIR}/draft ]; then
            _error
        fi

        rm -rf ${DIST}
        mkdir -p ${DIST}

        # copy local package
        _command "cp -rf ${SHELL_DIR}/draft/* ${DIST}"
        cp -rf ${SHELL_DIR}/draft/* ${DIST}

        _result "local package used."
    else
        if [ ! -d ${DIST} ]; then
            echo
            mkdir -p ${DIST}

            # download
            pushd ${DIST}
            curl -sL https://github.com/${THIS_REPO}/${THIS_NAME}/releases/download/${THIS_VERSION}/draft.tar.gz | tar xz
            popd

            _result "draft package downloaded."
        fi
    fi

    # package
    if [ -z ${PACKAGE} ]; then
        ls ${DIST} | sort > ${LIST}

        _select_one

        if [ ! -d ${DIST}/${SELECTED} ]; then
            _error
        fi

        _result "${SELECTED}"

        PACKAGE="${SELECTED}"
    fi

    # default
    if [ -f Jenkinsfile ]; then
        if [ -z ${NAME} ]; then
            NAME=$(cat Jenkinsfile | grep "def IMAGE_NAME = " | cut -d'"' -f2)
        fi
        if [ -z ${REPOSITORY_URL} ]; then
            REPOSITORY_URL=$(cat Jenkinsfile | grep "def REPOSITORY_URL = " | cut -d'"' -f2)
        fi
    fi
    if [ -z ${NAME} ]; then
        NAME=$(basename $(pwd))
    fi
    if [ -z ${REPOSITORY_URL} ]; then
        if [ -d .git ]; then
            REPOSITORY_URL=$(git config --get remote.origin.url | head -1 | xargs)
        fi
    fi

    # clear
    if [ ! -z ${FORCE} ] || [ ! -z ${DELETE} ]; then
        rm -rf charts
    fi

    # copy
    if [ -f ${DIST}/${PACKAGE}/dockerignore ]; then
        cp -rf ${DIST}/${PACKAGE}/dockerignore .dockerignore
    fi
    if [ -f ${DIST}/${PACKAGE}/draftignore ]; then
        cp -rf ${DIST}/${PACKAGE}/draftignore .draftignore
    fi
    if [ -f ${DIST}/${PACKAGE}/Dockerfile ]; then
        cp -rf ${DIST}/${PACKAGE}/Dockerfile Dockerfile
    fi
    if [ -f ${DIST}/${PACKAGE}/Jenkinsfile ]; then
        cp -rf ${DIST}/${PACKAGE}/Jenkinsfile Jenkinsfile
    fi
    if [ -f ${DIST}/${PACKAGE}/draft.toml ]; then
        cp -rf ${DIST}/${PACKAGE}/draft.toml draft.toml
    fi

    if [ -f Jenkinsfile ]; then
        # Jenkinsfile IMAGE_NAME
        _chart_replace "Jenkinsfile" "def IMAGE_NAME" "${NAME}"
        NAME="${REPLACE_VAL}"
    fi

    # cp charts/acme/ to charts/${NAME}/
    if [ -d ${DIST}/${PACKAGE}/charts ]; then
        mkdir -p charts/${NAME}
        cp -rf ${DIST}/${PACKAGE}/charts/acme/* charts/${NAME}/
    fi

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    if [ -f draft.toml ] && [ ! -z ${NAME} ]; then
        # draft.toml NAME
        _replace "s|NAMESPACE|${NAMESPACE}|" draft.toml
        _replace "s|NAME|${NAME}-${NAMESPACE}|" draft.toml
    fi

    if [ -d charts ] && [ ! -z ${NAME} ]; then
        # charts/${NAME}/Chart.yaml
        _replace "s|name: .*|name: ${NAME}|" charts/${NAME}/Chart.yaml

        # charts/${NAME}/values.yaml
        if [ -z ${REGISTRY} ]; then
            _replace "s|repository: .*|repository: ${NAME}|" charts/${NAME}/values.yaml
        else
            _replace "s|repository: .*|repository: ${REGISTRY}/${NAME}|" charts/${NAME}/values.yaml
        fi

        # charts path
        # mv charts/acme charts/${NAME}
    fi

    if [ -f Jenkinsfile ]; then
        # Jenkinsfile REPOSITORY_URL
        _chart_replace "Jenkinsfile" "def REPOSITORY_URL" "${REPOSITORY_URL}"
        REPOSITORY_URL="${REPLACE_VAL}"

        # Jenkinsfile REPOSITORY_SECRET
        _chart_replace "Jenkinsfile" "def REPOSITORY_SECRET" "${SECRET}"
        SECRET="${REPLACE_VAL}"
    fi

    if [ -d charts ]; then
        # Jenkinsfile CLUSTER
        _chart_replace "Jenkinsfile" "def CLUSTER" "${CLUSTER}"
        CLUSTER="${REPLACE_VAL}"

        # Jenkinsfile BASE_DOMAIN
        _chart_replace "Jenkinsfile" "def BASE_DOMAIN" "${BASE_DOMAIN}"
        BASE_DOMAIN="${REPLACE_VAL}"
    fi

    _config_save
}

_up() {
    if [ ! -f draft.toml ]; then
        _error "Not found draft.toml"
    fi
    if [ ! -d charts ]; then
        _error "Not found charts"
    fi

    # _init

    # name
    NAME="$(ls charts | head -1 | tr '/' ' ' | xargs)"

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    # charts/${NAME}/values.yaml
    if [ -z ${REGISTRY} ]; then
        _replace "s|repository: .*|repository: ${NAME}|" charts/${NAME}/values.yaml
    else
        _replace "s|repository: .*|repository: ${REGISTRY}/${NAME}|" charts/${NAME}/values.yaml
    fi

    # delete
    if [ ! -z ${FORCE} ] || [ ! -z ${DELETE} ]; then
        _command "helm delete ${NAME}-${NAMESPACE} --purge"
        helm delete ${NAME}-${NAMESPACE} --purge

        sleep 2
    fi

    # draft up
    _command "draft up -e ${NAMESPACE}"
    draft up -e ${NAMESPACE}

    DRAFT_LOGS=$(mktemp /tmp/valve-draft-logs.XXXXXX)

    # find draft error
    draft logs | grep error > ${DRAFT_LOGS}
    CNT=$(cat ${DRAFT_LOGS} | wc -l | xargs)
    if [ "x${CNT}" != "x0" ]; then
        _command "draft logs"
        draft logs
        _error "$(cat ${DRAFT_LOGS})"
    fi

    _command "helm ls ${NAME}-${NAMESPACE}"
    helm ls ${NAME}-${NAMESPACE}

    CNT=$(helm ls ${NAME}-${NAMESPACE} | wc -l | xargs)
    if [ "x${CNT}" == "x0" ]; then
        _error
    fi

    _waiting_pod "${NAMESPACE}" "${NAME}-${NAMESPACE}"

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_remote() {
    # _helm_init

    _helm_repo

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    # base domain
    BASE_DOMAIN="127.0.0.1.nip.io"

    LIST=/tmp/valve-charts-ls

    # chart name
    if [ -z ${NAME} ]; then
        curl -sL ${CHARTMUSEUM}/api/charts | jq 'keys[]' -r > ${LIST}

        _select_one

        _result "${SELECTED}"

        NAME="${SELECTED}"
    fi

    # version
    if [ -z ${VERSION} ]; then
        curl -sL ${CHARTMUSEUM}/api/charts/${NAME} | jq '.[] | {version} | .version' -r | sort -r | head -9 > ${LIST}

        _select_one

        _result "${SELECTED}"

        VERSION="${SELECTED}"
    fi

    # delete
    if [ ! -z ${FORCE} ] || [ ! -z ${DELETE} ]; then
        _command "helm delete ${NAME}-${NAMESPACE} --purge"
        helm delete ${NAME}-${NAMESPACE} --purge

        sleep 2
    fi

    # helm install
    _command "helm install ${NAME}-${NAMESPACE} chartmuseum/${NAME} --version ${VERSION} --namespace ${NAMESPACE}"
    helm upgrade --install ${NAME}-${NAMESPACE} chartmuseum/${NAME} --version ${VERSION} --namespace ${NAMESPACE} --devel \
                    --set fullnameOverride=${NAME}-${NAMESPACE} \
                    --set ingress.basedomain=${BASE_DOMAIN}

    _command "helm ls ${NAME}-${NAMESPACE}"
    helm ls ${NAME}-${NAMESPACE}

    CNT=$(helm ls ${NAME}-${NAMESPACE} | wc -l | xargs)
    if [ "x${CNT}" == "x0" ]; then
        _error
    fi

    _waiting_pod "${NAMESPACE}" "${NAME}-${NAMESPACE}"

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_all() {
    # _helm_init

    _command "helm ls --all"
    helm ls --all

    _command "kubectl get all --all-namespaces"
    kubectl get all --all-namespaces
}

_list() {
    # _helm_init

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    LIST=/tmp/valve-helm-ls

    _command "helm ls --all | grep ${NAMESPACE}"
    helm ls --all > ${LIST}
    cat ${LIST} | head -1
    cat ${LIST} | grep ${NAMESPACE}

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_describe() {
    # _helm_init

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    if [ -z ${NAME} ]; then
        LIST=/tmp/valve-pod-ls

        # get pod list
        _command "kubectl get pod -n ${NAMESPACE}"
        kubectl get pod -n ${NAMESPACE} | grep -v "NAME" | awk '{print $1}' > ${LIST}

        _select_one

        _result "${SELECTED}"

        NAME="${SELECTED}"
    fi

    _command "kubectl describe pod -n ${NAMESPACE} ${NAME}"
    kubectl describe pod -n ${NAMESPACE} ${NAME}
}

_logs() {
    # _helm_init

    # namespace
    NAMESPACE="${NAMESPACE:-development}"

    if [ -z ${NAME} ]; then
        LIST=/tmp/valve-pod-ls

        # get pod list
        _command "kubectl get pod -n ${NAMESPACE}"
        kubectl get pod -n ${NAMESPACE} | grep -v "NAME" | awk '{print $1}' > ${LIST}

        _select_one

        _result "${SELECTED}"

        NAME="${SELECTED}"
    fi

    _command "kubectl logs -n ${NAMESPACE} ${NAME}"
    kubectl logs -n ${NAMESPACE} ${NAME}
}

_remove() {
    # _helm_init

    if [ -z ${NAME} ]; then
        LIST=/tmp/valve-helm-ls

        # get helm list
        _command "helm ls --all"
        helm ls --all | grep -v "NAME" | awk '{print $1}' > ${LIST}

        _select_one

        _result "${SELECTED}"

        NAME="${SELECTED}"
    fi

    _command "helm delete ${NAME} --purge"
    helm delete ${NAME} --purge
}

_sample() {
    LIST=/tmp/valve-sample-ls

    echo "redis" > ${LIST}
    echo "sample-node" >> ${LIST}
    echo "sample-spring" >> ${LIST}
    echo "sample-tomcat" >> ${LIST}

    _select_one

    _result "${SELECTED}"

    NAME="${SELECTED}"

    # namespace
    NAMESPACE="${NAMESPACE:-default}"

    # base domain
    BASE_DOMAIN="127.0.0.1.nip.io"

    SAMPLE=$(mktemp /tmp/valve-${NAME}.XXXXXX.yaml)

    _get_yaml "sample/${NAME}" "${SAMPLE}"

    DOMAIN="${NAME}-${NAMESPACE}.${BASE_DOMAIN}"

    _replace "s/# type: SERVICE_TYPE/type: ClusterIP/" ${SAMPLE}
    _replace "s/INGRESS_DOMAIN/${DOMAIN}/" ${SAMPLE}

    _command "kubectl apply -f ${SAMPLE}"
    kubectl apply -f ${SAMPLE}

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_clean() {
    # rm -rf ${CONFIG}
    rm -rf /tmp/valve-*

    LIST=/tmp/valve-docker-ls

    docker ps -a -q > ${LIST}
    CNT=$(cat ${LIST} | wc -l | xargs)
    if [ "x${CNT}" != "x0" ]; then
        docker rm $(cat ${LIST})
    fi

    docker images -q > ${LIST}
    CNT=$(cat ${LIST} | wc -l | xargs)
    if [ "x${CNT}" != "x0" ]; then
        docker rmi -f $(cat ${LIST})
    fi
}

_chart_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3
    REPLACE_TYPE=$4

    if [ "${DEFAULT_VAL}" == "" ]; then
        Q="${REPLACE_KEY} : "
    else
        Q="${REPLACE_KEY} [${DEFAULT_VAL}] : "
    fi

    echo
    _read "${Q}"

    if [ -z ${ANSWER} ]; then
        REPLACE_VAL=${DEFAULT_VAL}
    else
        REPLACE_VAL=${ANSWER}
    fi

    if [ "${REPLACE_TYPE}" == "yaml" ]; then
        _command "sed -i -e s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}| ${REPLACE_FILE}"
        _replace "s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}|" ${REPLACE_FILE}
    else
        _command "sed -i -e s|${REPLACE_KEY} = .*|${REPLACE_KEY} = ${REPLACE_VAL}| ${REPLACE_FILE}"
        _replace "s|${REPLACE_KEY} = .*|${REPLACE_KEY} = \"${REPLACE_VAL}\"|" ${REPLACE_FILE}
    fi
}

_get_yaml() {
    _NAME=$1
    _DIST=$2

    if [ "${THIS_VERSION}" == "v0.0.0" ]; then
        cp -rf ${SHELL_DIR}/${_NAME}.yaml ${_DIST}
    else
        curl -sL https://raw.githubusercontent.com/${THIS_REPO}/${THIS_NAME}/master/${_NAME}.yaml > ${_DIST}
    fi
}

_run

_success "done."
