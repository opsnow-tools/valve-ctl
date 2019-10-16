# valve-ctl

[![GitHub release](https://img.shields.io/github/release/opsnow-tools/valve-ctl.svg)](https://github.com/opsnow-tools/valve-ctl/releases)
[![CircleCI](https://circleci.com/gh/opsnow-tools/valve-ctl.svg?style=svg)](https://circleci.com/gh/opsnow-tools/valve-ctl)

개발자가 쿠버네티스를 쉽게 사용할 수 있게 하는 CLI 도구 입니다.

개발자가 쿠버네티스에 애플리케이션을 배포하기 위해서는 다양한 설정 파일을 정의해야 합니다.
정의해야 하는 설정은 다음과 같은 것들이 있습니다.
* CI/CD Pipeline
* Dockerfile
* Kubernetes Manifest 

개발자가 해당 파일을 직접 작성하게 되면 비교적 오랜 학습 기간이 필요하고 개발팀 별로 배포 형상이 정형화 되지 않는 문제가 생깁니다. `valve` 명령을 통해서 개발자는 도커 이미지를 생성할 수 있고 해당 이미지를 운영 환경에 배포하기 위한 구성 파일과 CI/CD 파이프라인을 손쉽게 생성할 수 있습니다. 

`valve` 는 다음과 같은 설정 파일을 생성합니다.
* Jenkinsfile
* Dockerfile
* Helm Chart

기본으로 제공된느 설정 파일은 개발 언어, 빌드 도구, 런타임 베이스 이미지에 따라 달라집니다.
`valve`는 다음과 같은 설정 파일을 지원합니다.
* java-mvn-lib
* java-mvn-springboot
* java-mvn-tomcat
* js-npm-nginx
* js-npm-nodejs
* web-nginx
설정 파일 유형은 <개발 언어>-<빌드 도구>-<베이스 이미지>로 명명됩니다.

Jenkinsfile은 valve로 명명된 다른 프로젝트와 연동하여 동작합니다.
툴 구성 및 설정 파일은 초기에 제공된 그대로 사용할 수 있겠지만 필요에 따라 일부 수정이 필요합니다. 이러한 경우 valve 의 다른 프로젝트에 대한 이해가 필요합니다.
* [valve-tools](https://github.com/opsnow-tools/valve-tools)
  * Jenkins server, Docker registry, Chart Museum, Sonarqube, Sonatype Nexus 등을 설치합니다.
* [valve-builder](https://github.com/opsnow-tools/valve-builder)
  * 빌드, 배포 도구가 설치된 도커 이미지를 제공합니다.
* [valve-butler](https://github.com/opsnow-tools/valve-butler)
  * Jenkinsfile에 사용할 groovy script를 제공합니다.

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

> <참고 사항><br/> valve CLI 클라우드 네이티브 애플리케이션 개발을 위한 설정 파일 생성 및 설정 파일을 다루는 개발자 편의 기능을 제공할 예정입니다. 기존의 `valve`가 제공하는 기능의 일부가 수정될 수 있습니다.