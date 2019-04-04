# valve-ctl

[![GitHub release](https://img.shields.io/github/release/opsnow-tools/valve-ctl.svg)](https://github.com/opsnow-tools/valve-ctl/releases)

## install

```bash
curl -sL repo.opsnow.io/valve-ctl/install | bash
```

## usage

```bash
valve gen
valve up
```

## help

```text
================================================================================
             _                  _   _
 __   ____ _| |_   _____    ___| |_| |
 \ \ / / _' | \ \ / / _ \  / __| __| |
  \ V / (_| | |\ V /  __/ | (__| |_| |
   \_/ \__,_|_| \_/ \___|  \___|\__|_|  v0.x.x
================================================================================
Usage: valve {Command} [Arguments ..]

Commands:
    c, config               저장된 설정을 조회 합니다.

    i, init                 초기화를 합니다. Kubernetes 에 필요한 툴을 설치 합니다.
        -f, --force         가능하면 재설치 합니다.
        -d, --delete        기존 배포를 삭제 하고, 다음 작업을 수행합니다.

    g, gen                  프로젝트 배포에 필요한 패키지를 설치 합니다.
        -d, --delete        기존 패키지를 삭제 하고, 다음 작업을 수행합니다.

    u, up                   프로젝트를 Local Kubernetes 에 배포 합니다.
        -d, --delete        기존 배포를 삭제 하고, 다음 작업을 수행합니다.
        -r, --remote        Remote 프로젝트를 Local Kubernetes 에 배포 합니다.

    r, remote               Remote 프로젝트를 Local Kubernetes 에 배포 합니다.
        -n, --name=         프로젝트 이름을 알고 있을 경우 입력합니다.
        -v, --version=      프로젝트 버전을 알고 있을 경우 입력합니다.

    a, all                  배포된 리소스의 전체 list 를 조회 합니다.

    l, ls, list             배포된 리소스의 list 를 조회 합니다.
    d, desc                 배포된 리소스의 describe 를 조회 합니다.
    h, hpa                  배포된 리소스의 Horizontal Pod Autoscaler 를 조회 합니다.
    log, logs               배포한 리소스의 logs 를 조회 합니다.
        -N, --namespace=    지정된 namespace 를 조회 합니다.

    rm, remove              배포한 프로젝트를 삭제 합니다.
        -n, --name=         프로젝트 이름을 알고 있을 경우 입력합니다.

    clean                   저장된 설정을 모두 삭제 합니다.
        -d, --delete        docker 이미지도 모두 삭제 합니다.

    tools                   개발에 필요한 툴을 설치 합니다. (MacOS, Ubuntu 만 지원)
    update                  valve 를 최신버전으로 업데이트 합니다.
    v, version              valve 버전을 확인 합니다.
================================================================================
```
