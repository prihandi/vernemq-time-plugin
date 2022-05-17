FROM --platform=linux/amd64 coinbitdwi/elixir:1.13.4-no-jit AS build-app

ARG APP_ENV=dev

ENV MIX_ENV=${APP_ENV} \
    LANG=C.UTF-8 \
    PATH=/root/.mix/escripts:$PATH \
    REPLACE_OS_VARS=true \
    TERM=xterm \
    HEX_HTTP_TIMEOUT=300

RUN apt-get update && \
    apt-get -y install autoconf build-essential libssl-dev curl

RUN mix local.rebar --force &&  mix local.hex --force

WORKDIR /app

# For caching deps if not changed
COPY mix.exs  .
COPY mix.lock .
RUN mix deps.get
RUN mix deps.compile

COPY lib lib
RUN mix compile

RUN mkdir elixir && cp -R /usr/local/lib/elixir/* elixir/

# ------------------------------------------------ #

FROM --platform=linux/amd64 coinbitdwi/vernemq:latest-no-jit

ARG APP_ENV=dev

RUN apt-get update && \
    apt-get -y install iproute2 openssl jq curl libsnappy-dev && \
    rm -rf /var/lib/apt/lists/* 
RUN addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    DOCKER_VERNEMQ_LOG__CONSOLE__LEVEL=debug \
    PATH="/vernemq/bin:$PATH" \
    LANG=C.UTF-8 \
    REPLACE_OS_VARS=true

WORKDIR /vernemq

RUN cp -R /vernemq-build/release/* /vernemq/ && chown -R 10000:10000 /vernemq

COPY --chown=10000:10000 --from=build-app /app/elixir /vernemq/plugins/elixir
COPY --chown=10000:10000 --from=build-app /app/_build/${APP_ENV} /vernemq/plugins/vernemq_time_plugin

COPY --chown=10000:10000 ./vernemq_files/vernemq.sh /usr/sbin/start_vernemq
COPY --chown=10000:10000 ./vernemq_files/vm.args /vernemq/etc/vm.args

RUN ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

RUN tar -czf /vernemq-build/vernemq-time.tar /vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 4000 1883 8883 8080 44053 4369 8888 \
    9100 9101 9102 9103 9104 9105 9106 9107 9108 9109 

VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

HEALTHCHECK CMD vernemq ping | grep -q pong

USER vernemq
CMD ["start_vernemq"]