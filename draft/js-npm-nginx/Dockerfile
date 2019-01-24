# Dockerfile

FROM nginx:1.13-alpine
RUN apk add --no-cache bash curl
EXPOSE 80
COPY dist /usr/share/nginx/html
