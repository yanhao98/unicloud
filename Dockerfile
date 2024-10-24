FROM python:3.13-alpine3.20 AS base

ENV TZ=Asia/Shanghai
ARG PIP_NO_CACHE_DIR=off
ARG PACKAGES_FOR_BUILD="python3-dev gcc musl-dev linux-headers"
ARG PACKAGES_FOR_RUNTIME="dumb-init nginx supervisor openssh logrotate"

RUN apk add --no-cache \
    $PACKAGES_FOR_BUILD \
    $PACKAGES_FOR_RUNTIME \
    && pip3 install -qq --break-system-packages flask flask_restful uwsgi requests  flask-basicAuth flask-autoindex psutil apscheduler sqlalchemy \
    && apk del $PACKAGES_FOR_BUILD \
    && rm -rf /var/cache/* /tmp/*

# 🐳 
FROM base AS build_unison
# ARG UNISON_VERSION=2.53.5
RUN apk add --no-cache make ocaml musl-dev libc-dev \
    # && wget -qO- https://github.com/bcpierce00/unison/archive/refs/tags/v${UNISON_VERSION}.tar.gz | tar -xzf - -C /tmp \
    && wget -qO- https://github.com/bcpierce00/unison/archive/refs/heads/master.tar.gz | tar -xzf - -C /tmp \
    # && cd /tmp/unison-${UNISON_VERSION} \
    && cd /tmp/unison-master \
    && make \
    && src/unison -version && src/unison-fsmonitor -version \
    && cp src/unison src/unison-fsmonitor /usr/bin/

# 🐳 final image
FROM base
COPY --from=build_unison /usr/bin/unison /usr/bin/unison
RUN mkdir -p /var/run/sshd /run/nginx /usr/local/unicloud
ADD app/    /usr/local/unicloud/
ADD app_client/    /usr/local/unicloud_client/
ADD conf/sshd/client_root_ssh_config /data/.ssh/config
ADD conf/sshd/sshd_config_alpine /etc/sshd_config
ADD conf/sshd/sshd_config_alpine_debug /etc/sshd_config_debug
RUN mv /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf.install
RUN rm -f /etc/logrotate.d/*
ADD conf/nginx/default.conf /etc/nginx/http.d/default.conf
ADD conf/logrotate.d/ /etc/logrotate.d/
ADD start/ /start/
WORKDIR "/start"

RUN sed -i 's|/root|/data|g' /etc/passwd

EXPOSE 22
EXPOSE 80
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["python3","-u","start.py"]
