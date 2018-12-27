# Dockerfile

FROM node:10-alpine
RUN apk add --no-cache bash
EXPOSE 3000
WORKDIR /data
CMD ["npm", "run", "start"]
ADD src /data
