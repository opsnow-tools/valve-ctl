# Dockerfile

FROM node:10
ENV TZ Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
EXPOSE 3000
ADD src /data
WORKDIR /data
CMD ["node", "server.js"]
