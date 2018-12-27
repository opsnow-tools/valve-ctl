# Dockerfile

FROM openjdk:8-jre-alpine
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
ENV TZ Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apk add --no-cache bash
EXPOSE 8080
WORKDIR /data
ENTRYPOINT exec java $JAVA_OPTS -jar ROOT.jar
COPY ./target/*.jar /data/ROOT.jar
