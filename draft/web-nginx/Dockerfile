# Dockerfile

FROM nginx:1.13-alpine
ENV TZ Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apk add --no-cache bash
EXPOSE 80
COPY src /usr/share/nginx/html
