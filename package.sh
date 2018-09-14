#!/bin/bash

curl -s https://api.github.com/rate_limit
echo

USERNAME=${1:-opsnow-tools}
REPONAME=${2:-valve-tee}

rm -rf target
mkdir -p target/dist
mkdir -p target/charts

# OS_NAME
OS_NAME="$(uname | awk '{print tolower($0)}')"

echo "OS_NAME=${OS_NAME}"

# VERSION
VERSION=$(curl -s https://api.github.com/repos/${USERNAME}/${REPONAME}/releases/latest | grep tag_name | cut -d'"' -f4 | xargs)

if [ -z ${VERSION} ]; then
    VERSION=$(cat ./VERSION | xargs)
else
    MAJOR=$(echo ./VERSION | cut -d'.' -f1 | xargs)
    MINOR=$(echo ./VERSION | cut -d'.' -f2 | xargs)

    LATEST_MAJOR=$(echo ${VERSION} | cut -d'.' -f1 | xargs)
    LATEST_MINOR=$(echo ${VERSION} | cut -d'.' -f2 | xargs)

    if [ "${MAJOR}" != "${LATEST_MAJOR}" ] || [ "${MINOR}" != "${LATEST_MINOR}" ]; then
        VERSION=$(cat ./VERSION | xargs)
    fi

    # add
    VERSION=$(echo ${VERSION} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')
fi

printf "${VERSION}" > target/VERSION

echo "VERSION=${VERSION}"
echo

# 755
find ./** | grep [.]sh | xargs chmod 755

# tee
cp -rf tee.sh target/dist/tee

# version
if [ "${OS_NAME}" == "linux" ]; then
    sed -i -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" target/dist/tee
elif [ "${OS_NAME}" == "darwin" ]; then
    sed -i "" -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" target/dist/tee
fi

# target/
cp -rf install.sh target/install
cp -rf tools.sh   target/tools

# target/dist/draft.tar.gz
pushd draft
tar -czf ../target/dist/draft.tar.gz *
popd
echo

# target/charts/
cp -rf charts/* target/charts/

# ls
ls -al target
ls -al target/dist
