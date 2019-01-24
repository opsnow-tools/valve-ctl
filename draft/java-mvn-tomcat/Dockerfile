# Dockerfile

FROM tomcat:8-jre8-alpine
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
RUN rm -rf /usr/local/tomcat/webapps/*
RUN apk add --no-cache bash curl
EXPOSE 8080
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war
