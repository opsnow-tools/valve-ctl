# Dockerfile

FROM node:10-alpine
ENV TZ Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apk add --no-cache bash
EXPOSE 3000
ADD src /data
WORKDIR /data
CMD ["npm", "run", "start"]
