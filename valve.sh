#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
SUB=$2

FORCE=

NAME=
VERSION=0.0.0

SECRET=
PACKAGE=

NAMESPACE=
CLUSTER=

BASE_DOMAIN=
JENKINS=
REGISTRY=
CHARTMUSEUM=
SONARQUBE=
NEXUS=

CONFIG=${HOME}/.valve-ctl

touch ${CONFIG} && . ${CONFIG}

for v in "$@"; do
    case ${v} in
    --name=*)
        NAME="${v#*=}"
        shift
        ;;
    --version=*)
        VERSION="${v#*=}"
        shift
        ;;
    --secret=*)
        SECRET="${v#*=}"
        shift
        ;;
    --package=*)
        PACKAGE="${v#*=}"
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
    --force=*)
        FORCE="${v#*=}"
        shift
        ;;
    --this=*)
        THIS_VERSION="${v#*=}"
        shift
        ;;
    *)
        shift
        ;;
    esac
done

################################################################################

command -v tput > /dev/null || TPUT=false

_bar() {
    _echo "================================================================================"
}

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
    _echo "# $@" 4
}

_command() {
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

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

_logo() {
    #figlet valve ctl
    _bar
    _echo "             _                  _   _  "
    _echo " __   ____ _| |_   _____    ___| |_| | "
    _echo " \ \ / / _' | \ \ / / _ \  / __| __| | "
    _echo "  \ V / (_| | |\ V /  __/ | (__| |_| | "
    _echo "   \_/ \__,_|_| \_/ \___|  \___|\__|_|  ${THIS_VERSION} "
    _bar
}

_usage() {
    _logo
    _echo " Usage: $0 {gen|up|rm|tools|update|version}"
    _bar
    _error
}

################################################################################

_run() {
    case ${CMD} in
        init)
            _draft_init
            ;;
        gen)
            _draft_gen
            ;;
        up)
            _draft_up
            ;;
        dn|launch)
            _draft_dn
            ;;
        rm|delete)
            _draft_rm
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
    curl -sL repo.opsnow.io/valve-ctl/tools | bash
    exit 0
}

_update() {
    curl -sL repo.opsnow.io/valve-ctl/install | bash
    exit 0
}

_version() {
    _success ${THIS_VERSION} 2
}

_config_save() {
    echo "# valve config" > ${CONFIG}
    echo "SECRET=${SECRET}" >> ${CONFIG}
    echo "PACKAGE=${PACKAGE}" >> ${CONFIG}
    echo "NAMESPACE=${NAMESPACE}" >> ${CONFIG}
    echo "CLUSTER=${CLUSTER}" >> ${CONFIG}
    echo "BASE_DOMAIN=${BASE_DOMAIN}" >> ${CONFIG}
    echo "JENKINS=${JENKINS}" >> ${CONFIG}
    echo "REGISTRY=${REGISTRY}" >> ${CONFIG}
    echo "CHARTMUSEUM=${CHARTMUSEUM}" >> ${CONFIG}
    echo "SONARQUBE=${SONARQUBE}" >> ${CONFIG}
    echo "NEXUS=${NEXUS}" >> ${CONFIG}
}

_waiting_pod() {
    _NS=${1}
    _NM=${2}
    SEC=${3:-30}

    # # TODO use deploy
    # _command "kubectl get deploy ${_NM} -n ${_NS} | grep ${_NM}"

    # IDX=0
    # while [ 1 ]; do
    #     kubectl get deploy ${_NM} -n ${_NS} | grep ${_NM} | head -1 > /tmp/valve-deploy-status
    #     cat /tmp/valve-deploy-status

    #     DESIRED=$(cat /tmp/valve-deploy-status | awk '{print $2}')
    #     CURRENT=$(cat /tmp/valve-deploy-status | awk '{print $3}')
    #     AVAILAB=$(cat /tmp/valve-deploy-status | awk '{print $5}')

    #     if [ "${DESIRED}" == "${CURRENT}" ] && [ "${DESIRED}" == "${AVAILAB}" ]; then
    #         break
    #     elif [ "x${IDX}" == "x${SEC}" ]; then
    #         _error "Timeout"
    #     fi

    #     IDX=$(( ${IDX} + 1 ))
    #     sleep 2
    # done

    _command "kubectl get pod -n ${_NS} | grep ${_NM}"

    IDX=0
    while [ 1 ]; do
        kubectl get pod -n ${_NS} | grep ${_NM} | head -1 > /tmp/valve-pod-status
        cat /tmp/valve-pod-status

        STATUS=$(cat /tmp/valve-pod-status | awk '{print $3}')
        if [ "${STATUS}" == "Running" ]; then
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
        printf "%3s. %s\n" "$IDX" "$VAL";
    done < ${LIST}

    CNT=$(cat ${LIST} | wc -l | xargs)

    echo
    _read "Please select one. (1-${CNT}) : "

    SELECTED=
    if [ -z ${ANSWER} ]; then
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

_helm_init() {
    _command "helm init"
    helm init

    # waiting tiller
    _waiting_pod "kube-system" "tiller"

    _command "helm version"
    helm version

    _helm_repo
}

_helm_repo() {
    # curl -sL chartmuseum-devops.demo.opsnow.com/api/charts | jq -C '.'
    if [ ! -z ${CHARTMUSEUM} ]; then
        _command "helm repo add chartmuseum https://${CHARTMUSEUM}"
        helm repo add chartmuseum https://${CHARTMUSEUM}
    fi

    _command "helm repo update"
    helm repo update

    _config_save
}

_helm_apply() {
    _NS=$1
    _NM=$2

    CNT=$(helm ls ${_NM} | wc -l | xargs)

    if [ "x${CNT}" == "x0" ] || [ ! -z ${FORCE} ]; then
        CHART=/tmp/${_NM}.yaml

        curl -sL https://raw.githubusercontent.com/opsnow-tools/valve-ctl/master/charts/${_NM}.yaml > ${CHART}

        CHART_VERSION=$(cat ${CHART} | grep chart-version | awk '{print $3}')

        if [ -z ${CHART_VERSION} ] || [ "${CHART_VERSION}" == "latest" ]; then
            _command "helm upgrade --install ${_NM} stable/${_NM}"
            helm upgrade --install ${_NM} stable/${_NM} --namespace ${_NS} -f ${CHART}
        else
            _command "helm upgrade --install ${_NM} stable/${_NM}" --version ${CHART_VERSION}
            helm upgrade --install ${_NM} stable/${_NM} --namespace ${_NS} -f ${CHART} --version ${CHART_VERSION}
        fi
    fi
}

_draft_init() {
    _helm_init

    _command "draft init"
    draft init

    _command "draft version"
    draft version

    NAMESPACE="kube-public"

    # local tools
    _helm_apply "${NAMESPACE}" "docker-registry"
    _helm_apply "${NAMESPACE}" "metrics-server"
    _helm_apply "${NAMESPACE}" "nginx-ingress"

    if [ "x${ING_CNT}" == "x0" ] || [ "x${REG_CNT}" == "x0" ]; then
        _waiting_pod "${NAMESPACE}" "docker-registry"
        _waiting_pod "${NAMESPACE}" "nginx-ingress"
    fi

    draft config set disable-push-warning 1

    # curl -sL docker-registry.127.0.0.1.nip.io:30500/v2/_catalog | jq -C '.'
    REGISTRY="docker-registry.127.0.0.1.nip.io:30500"

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

_draft_gen() {
    _result "draft package version: ${THIS_VERSION}"

    DIST=/tmp/valve-draft-${THIS_VERSION}
    LIST=/tmp/valve-draft-ls

    if [ ! -d ${DIST} ]; then
        echo
        mkdir -p ${DIST}

        # download
        pushd ${DIST}
        curl -sL https://github.com/opsnow-tools/valve-ctl/releases/download/${THIS_VERSION}/draft.tar.gz | tar xz
        popd

        echo
        _result "draft package downloaded."
    fi

    # find all
    ls ${DIST} > ${LIST}

    _select_one

    if [ ! -d ${DIST}/${SELECTED} ]; then
        _error
    fi

    echo
    _result "${SELECTED}"

    rm -rf charts

    # copy
    if [ -d ${DIST}/${SELECTED}/charts ]; then
        cp -rf ${DIST}/${SELECTED}/charts charts
    fi
    if [ -f ${DIST}/${SELECTED}/dockerignore ]; then
        cp -rf ${DIST}/${SELECTED}/dockerignore .dockerignore
    fi
    if [ -f ${DIST}/${SELECTED}/draftignore ]; then
        cp -rf ${DIST}/${SELECTED}/draftignore .draftignore
    fi
    if [ -f ${DIST}/${SELECTED}/Dockerfile ]; then
        cp -rf ${DIST}/${SELECTED}/Dockerfile Dockerfile
    fi
    if [ -f ${DIST}/${SELECTED}/Jenkinsfile ]; then
        cp -rf ${DIST}/${SELECTED}/Jenkinsfile Jenkinsfile
    fi
    if [ -f ${DIST}/${SELECTED}/draft.toml ]; then
        cp -rf ${DIST}/${SELECTED}/draft.toml draft.toml
    fi

    if [ -f Jenkinsfile ]; then
        # Jenkinsfile IMAGE_NAME
        DEFAULT=$(basename $(pwd))
        _chart_replace "Jenkinsfile" "def IMAGE_NAME" "${DEFAULT}"
        NAME="${REPLACE_VAL}"
    fi

    if [ -f draft.toml ] && [ ! -z ${NAME} ]; then
        # draft.toml NAME
        _replace "s|NAME|${NAME}|" draft.toml
    fi

    if [ -d charts ] && [ ! -z ${NAME} ]; then
        # charts/acme/Chart.yaml
        _replace "s|name: .*|name: ${NAME}|" charts/acme/Chart.yaml

        # charts/acme/values.yaml
        if [ -z ${REGISTRY} ]; then
            _replace "s|repository: .*|repository: ${NAME}|" charts/acme/values.yaml
        else
            _replace "s|repository: .*|repository: ${REGISTRY}/${NAME}|" charts/acme/values.yaml
        fi

        # charts path
        mv charts/acme charts/${NAME}
    fi

    if [ -f Jenkinsfile ]; then
        # Jenkinsfile REPOSITORY_URL
        DEFAULT=
        if [ -d .git ]; then
            DEFAULT=$(git config --get remote.origin.url | head -1 | xargs)
        fi
        _chart_replace "Jenkinsfile" "def REPOSITORY_URL" "${DEFAULT}"
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

_draft_up() {
    _draft_init

    if [ ! -f draft.toml ]; then
        _error "Not found draft.toml"
    fi

    NAME="$(cat draft.toml | grep "name =" | cut -d'"' -f2 | xargs)"

    NAMESPACE="development"

    # charts/acme/values.yaml
    if [ -z ${REGISTRY} ]; then
        _replace "s|repository: .*|repository: ${NAME}|" charts/${NAME}/values.yaml
    else
        _replace "s|repository: .*|repository: ${REGISTRY}/${NAME}|" charts/${NAME}/values.yaml
    fi

    # TODO delete
    # _command "helm delete ${NAME} --purge"
    # helm delete ${NAME} --purge

    _command "draft up -e ${NAMESPACE}"
    draft up -e ${NAMESPACE}

    DRAFT_LOGS=$(mktemp /tmp/valve-draft-logs.XXXXXX)

    draft logs | grep error > ${DRAFT_LOGS}
    COUNT=$(cat ${DRAFT_LOGS} | wc -l | xargs)
    if [ "x${COUNT}" != "x0" ]; then
        _command "draft logs"
        draft logs
        _error "$(cat ${DRAFT_LOGS})"
    fi

    _command "helm ls ${NAME}"
    helm ls ${NAME}

    _waiting_pod "${NAMESPACE}" "${NAME}"

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_draft_dn() {
    _helm_init

    if [ -z ${CHARTMUSEUM} ]; then
        _read "CHARTMUSEUM : "

        if [ -z ${ANSWER} ]; then
            _error
        fi

        CHARTMUSEUM="${ANSWER}"

        _helm_repo
    fi

    NAMESPACE="development"
    BASE_DOMAIN="127.0.0.1.nip.io"

    # curl -sL chartmuseum-devops.coruscant.opsnow.com/api/charts | jq -C 'keys[]' -r
    # curl -sL chartmuseum-devops.demo.opsnow.com/api/charts/sample-node | jq -C '.[] | {version} | .version' -r

    LIST=/tmp/valve-charts-ls

    # chart name
    curl -sL ${CHARTMUSEUM}/api/charts | jq -C 'keys[]' -r > ${LIST}

    _select_one

    echo
    _result "${SELECTED}"
    echo

    NAME="${SELECTED}"

    # version
    curl -sL ${CHARTMUSEUM}/api/charts/${NAME} | jq -C '.[] | {version} | .version' -r | head -7 > ${LIST}

    _select_one

    echo
    _result "${SELECTED}"
    echo

    VERSION="${SELECTED}"

    # helm install
    helm upgrade --install $NAME chartmuseum/$NAME \
                    --version $VERSION --namespace $NAMESPACE --devel \
                    --set fullnameOverride=$NAME \
                    --set ingress.basedomain=$BASE_DOMAIN

    _command "helm ls ${NAME}"
    helm ls ${NAME}

    _waiting_pod "${NAMESPACE}" "${NAME}"

    _command "kubectl get pod,svc,ing -n ${NAMESPACE}"
    kubectl get pod,svc,ing -n ${NAMESPACE}
}

_draft_rm() {
    _draft_init

    LIST=/tmp/valve-helm-ls

    _command "helm ls --all"
    helm ls --all | grep development | awk '{print $1}' > ${LIST}

    _select_one

    echo
    _result "${SELECTED}"
    echo

    _command "helm delete ${SELECTED} --purge"
    helm delete ${SELECTED} --purge
}

_chart_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3
    REPLACE_TYPE=$4

    echo

    if [ "${DEFAULT_VAL}" == "" ]; then
        _read "${REPLACE_KEY} : "
    else
        _read "${REPLACE_KEY} [${DEFAULT_VAL}] : "
    fi

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

_run

_success "done."
