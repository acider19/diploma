# Образ основан на unprivileged-варианте nginx: процесс слушает 8080
# и не требует root, что соответствует restricted Pod Security Standard.
FROM nginxinc/nginx-unprivileged:1.27-alpine

ARG APP_VERSION=dev

# Статика и версия сборки.
COPY site/ /usr/share/nginx/html/
RUN echo "${APP_VERSION}" > /usr/share/nginx/html/version

USER 101
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
