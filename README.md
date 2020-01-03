# valve-ctl

[![GitHub release](https://img.shields.io/github/release/opsnow-tools/valve-ctl.svg)](https://github.com/opsnow-tools/valve-ctl/releases)
[![CircleCI](https://circleci.com/gh/opsnow-tools/valve-ctl.svg?style=svg)](https://circleci.com/gh/opsnow-tools/valve-ctl)

개발자가 밸브를 통해 구축된 인프라에 애플리케이션을 개발하고 배포를 쉽게 하기 위해 제공되는 CLI 도구입니다.
애플리케이션 빌드, 배포 설정을 표준 템플릿으로 제공하며 개발자 PC에서 컨테이너를 구동하고 테스트할 방법을 제공합니다.

## 설치 방법
```bash
curl -sL repo.opsnow.io/valve-ctl/install | bash

# to install a specific version
curl -sL repo.opsnow.io/valve-ctl/install | bash -s v2.0.3
```

## help

```bash
valve -h
```

## Valve 빠르게 사용해보기
밸브를 설치하고 빠르게 사용해 보고 싶다면 다음 가이드를 따라 진행해 보세요.
* [개발자를 위한 밸브 퀵 스타트](./hands-on/valve-developer-quickstart.md)

## 주요 기능
Valve-Ctl은 다음과 같은 기능을 제공합니다.
* 컨테이너 빌드, 배포 표준 템플릿 제공
* 사용자 정의 표준 템플릿 정의 및 사용 방법 제공
* 개발중인 애플리케이션 개인 테스트 방법 제공
* 사용자 CLI 정의 및 통합 방법 제공

## 컨테이너 빌드, 배포 표준 템플릿 제공
밸브로 구축할 수 있는 인프라는 EC2 기반 쿠버네티스 클러스터(valve-kops)와 EKS 기반 쿠버네티스 클러스터(valve-eks)가 있습니다.

개발자가 이들 환경에 애플리케이션을 배포하기 위해서는 빌드, 배포를 위한 CI/CD 프로세스를 정의해야 하고 배포되는 인프라가 쿠버네티스라면 컨테이너 이미지를 생성하기 위한 Dockerfile, 쿠버네티스 오브젝트를 정의한 Manifest 파일 등을 정의해야 합니다. 개발자가 이러한 작업에 익숙하다면 큰 문제가 없겠지만, 그렇지 않다면 비교적 오랜 학습 기간이 필요합니다. 그리고 개발팀이 여러 개로 나누어져 있는 비교적 큰 규모의 프로젝트라고 한다면 개발팀별로 정형화 되지 않은 빌드, 배포 설정을 하게 되어 향후 서비스를 일관성 있게 관리할 수 없게 되고 이로 인해 개발, 운영 비용의 증가로 이어질 수 있습니다. 이런 문제는 잘 정의된 표준 템플릿을 사용하고 개발자가 이를 사용하도록 함으로써 해결할 수 있습니다.

개발자는 valve-ctl 을 사용하여 배포 유형에 맞는 템플릿을 선택하고 약간의 수정만으로 운영 환경까지 배포 가능한 파이프라인을 생성할 수 있습니다.

예를 들어, 다음은 java로 작성된 springboot 기반 애플리케이션 템플릿을 프로젝트에 적용하는 명령입니다.
실제 명령은 `valve`를 사용합니다. 명령 수행은 git 레파지토리 홈에서 진행해야 합니다.
```
$ valve fetch --n java-mvn-springboot
```
위 명령의 결과로 다음과 같은 파일이 자동 생성됩니다.
```
$ tree
.
├── Dockerfile
├── Jenkinsfile
└── charts
    └── sample-springboot
        ├── Chart.yaml
        ├── templates
        │   ├── NOTES.txt
        │   ├── _helpers.tpl
        │   ├── configmap.yaml
        │   ├── deployment.yaml
        │   ├── hpa.yaml
        │   ├── ingress.yaml
        │   ├── pdb.yaml
        │   ├── secret.yaml
        │   └── service.yaml
        └── values.yaml
```

생성된 파일에는 CI/CD를 위한 Jenkinsfile, 도커 이미지 생성을 위한 Dockerfile, 쿠버네티스 오브젝트를 정의하기 위한 helm 차트 등이 있습니다. 이를 통해 개발자는 빌드, 배포를 위한 설정 작업을 최소화할 수 있으며 표준화된 방법을 사용하여 CI/CD 파이프라인과 관련된 공통 이슈에 효율적으로 대응할 수 있습니다.

현재 밸브가 제공하는 표준 템플릿은 다음 명령으로 확인할 수 있습니다.
```
$ valve search
[Default Template List]
R-batch
java-mvn-lib
java-mvn-springboot
java-mvn-tomcat
js-npm-nginx
js-npm-nodejs
terraform
web-nginx
```

각 템플릿은 프로젝트의 언어, 빌드 도구, 도커 베이스 이미지에 따라 구성되어 있고 앞서 java-mvn-springboot 의 결과에서 확인한 것처럼 여러 개의 설정 파일로 이루어져 있습니다. 대부분 템플릿을 수정없이 사용할 수 있지만 조금 특별한 파이프라인, 배포 설정을 하려고 하면 템플릿 파일의 역할과 수정 방법을 알아야 할 때가 있습니다.

다음 문서들은 템플릿을 수정할 때 참고할 수 있는 문서들입니다.
* [밸브 Jenkinsfile 구성 및 수정 방법]()
* [밸브 Dockerfile 구성 및 수정 방법]()
* [밸브 Helm 차트 구성 및 수정 방법]()

## 사용자 정의 표준 템플릿 정의 및 사용 방법 제공
밸브가 기본으로 제공하는 표준 템플릿은 개발 언어, 빌드 도구, 런타임 기초 이미지에 따라 구분되어 제공됩니다. 프로젝트의 유형에 따라 밸브가 제공하는 표준 템플릿을 그대로 사용하는 것 보다는 완전히 새로운 템플릿을 정의해야 할 수 있습니다. 예를 들어 개발팀은 develop, master, release 브랜치를 사용하는 gitflow 방식을 사용하고 싶을 수 있습니다. 밸브는 master 브랜치로 만 관리하는 github flow를 사용합니다. 또 개발팀은 컨테이너가 아니라 VM을 사용하고 싶을 수 있습니다. 그리고 CI/CD를 위한 도구로 젠킨스를 사용하고 싶지 않을 수도 있습니다.

모든 유형의 템플릿을 밸브가 제공할 수 없기 때문에 프로젝트에 최적화된 템플릿을 직접 정의하고 사용할 수 있는 방법이 필요합니다.

다음 명령은 이렇게 정의된 사용자 템플릿을 밸브가 사용할 수 있게 등록하는 명령입니다.
아래는 참고를 위해서 표준 템플릿을 사용자 템플릿으로 재등록하는 예제입니다. `name`과 URL은 수정해서 사용하시기 바랍니다.
```
valve repo add --name example --url https://github.com/opsnow-tools/valve-template.git
```

이제 사용 가능한 템플릿을 조회하면 다음과 같은 결과를 얻을 수 있습니다. 표준 템플릿 목록이 사용자 템플릿으로도 확인되는 것을 확인할 수 있습니다.
```
$ valve search

[Default Template List]
R-batch
java-mvn-lib
java-mvn-springboot
java-mvn-tomcat
js-npm-nginx
js-npm-nodejs
terraform
web-nginx

[Custom Template List]   ex) [Repo Name]/[Template Name]
example/R-batch
example/java-mvn-lib
example/java-mvn-springboot
example/java-mvn-tomcat
example/js-npm-nginx
example/js-npm-nodejs
example/terraform
example/web-nginx
```

사용자 템플릿을 레포지토리는 `레포지토리 홈 > templates > 사용자 템플릿 폴더` 의 디렉터리 구조를 따라야 합니다. 표준 템플릿을 정의한 [valve-template](https://github.com/opsnow-tools/valve-template) 프로젝트도 해당 폴더 구조를 따르고 있습니다.
```
$ tree -L 2 ./valve-template 
./valve-template
├── README.md
└── templates
    ├── R-batch
    ├── java-mvn-lib
    ├── java-mvn-springboot
    ├── java-mvn-tomcat
    ├── js-npm-nginx
    ├── js-npm-nodejs
    ├── terraform
    └── web-nginx
```

다음은 사용자 템플릿 생성을 실습해 볼 수 있는 가이드 문서 링크입니다. 만약 사용자 템플릿을 직접 생성해보기 원한다면 다음 문서의 사용자 템플릿 생성 부분을 참고하시기 바랍니다.
* [사용자 정의 템플릿 생성 및 사용 핸즈온]()

## 개발중인 애플리케이션 개인 테스트 방법 제공
개발자가 컨테이너, 쿠버네티스 개발 환경에 익숙하지 않은 경우 개발자 PC에서 개발 중인 애플리케이션을 컨테이너로 구동하고 테스트하지 못하고 master 브랜치에 병합할 수 있습니다. 밸브는 적용된 템플릿으로부터 개발자 PC 구동 중인 docker desktop, minikube 등을 사용하여 손쉽게 개발자 로컬 환경에서 테스트 할 수 있는 방법을 제공합니다.

다음은 개발자 환경에서 개발중인 애플리케이션을 컨테이너로 구동하는 명령입니다.
```
$ valve on
```
다음은 테스트 진행 후 구동된 컨테이너를 종료하는 명령입니다.
```
$ valve off
```

## 사용자 CLI 정의 및 통합 방법 제공
TBD

## valve-ctl 명령어
```
================================================================================
            _                  _   _   ____
__   ____ _| |_   _____    ___| |_| | |___ \
\ \ / / _` | \ \ / / _ \  / __| __| |   __) |
 \ V / (_| | |\ V /  __/ | (__| |_| |  / __/
  \_/ \__,_|_| \_/ \___|  \___|\__|_| |_____|
================================================================================
Version : v2.0.64
Usage: valve {Command} params..

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
```

## 관련 프로젝트
valve-ctl 은 다음과 같은 밸브 프로젝트와 연동하여 동작합니다.
* [valve-tools](https://github.com/opsnow-tools/valve-tools)
  * Jenkins server, Docker registry, Chart Museum, Sonarqube, Sonatype Nexus 등을 설치합니다.
* [valve-builder](https://github.com/opsnow-tools/valve-builder)
  * 빌드, 배포 도구가 설치된 도커 이미지를 제공합니다.
* [valve-butler](https://github.com/opsnow-tools/valve-butler)
  * Jenkinsfile에 사용할 groovy script를 제공합니다.

## valve-ctl 개발자 가이드
TBD

## 라이선스 정보
TBD