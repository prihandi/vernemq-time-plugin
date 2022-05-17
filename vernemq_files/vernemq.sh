#!/usr/bin/env bash

IP_ADDRESS=$(ip -4 addr show ${DOCKER_NET_INTERFACE:-eth0} | grep -oE '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | sed -e "s/^[[:space:]]*//" | head -n 1)
IP_ADDRESS=${DOCKER_IP_ADDRESS:-${IP_ADDRESS}}

# Ensure the Erlang node name is set correctly
if env | grep "DOCKER_VERNEMQ_NODENAME" -q; then
    sed -i.bak -r "s/-name VerneMQ@.+/-name VerneMQ@${DOCKER_VERNEMQ_NODENAME}/" /vernemq/etc/vm.args
else
    sed -i.bak -r "s/-name VerneMQ@.+/-name VerneMQ@${IP_ADDRESS}/" /vernemq/etc/vm.args
fi

sed -i '/########## Start ##########/,/########## End ##########/d' /vernemq/etc/vernemq.conf

echo "########## Start ##########" >> /vernemq/etc/vernemq.conf

echo "erlang.distribution.port_range.minimum = 9100" >> /vernemq/etc/vernemq.conf
echo "erlang.distribution.port_range.maximum = 9109" >> /vernemq/etc/vernemq.conf
echo "listener.tcp.default = ${IP_ADDRESS}:1883" >> /vernemq/etc/vernemq.conf
echo "listener.ws.default = ${IP_ADDRESS}:8080" >> /vernemq/etc/vernemq.conf
echo "listener.vmq.clustering = ${IP_ADDRESS}:44053" >> /vernemq/etc/vernemq.conf
echo "listener.http.metrics = ${IP_ADDRESS}:8888" >> /vernemq/etc/vernemq.conf

# set auth and acl configuration
echo "allow_anonymous = on" >> /vernemq/etc/vernemq.conf
echo "plugins.vmq_passwd = on" >> /vernemq/etc/vernemq.conf
echo "plugins.vmq_acl = on" >> /vernemq/etc/vernemq.conf

# Enable Elixir plugin
echo "plugins.elixir = on" >> /vernemq/etc/vernemq.conf
echo "plugins.elixir.path = /vernemq/plugins/elixir" >> /vernemq/etc/vernemq.conf

# Enable project plugin
echo "plugins.vernemq_time_plugin = on" >> /vernemq/etc/vernemq.conf
echo "plugins.vernemq_time_plugin.path = /vernemq/plugins/vernemq_time_plugin" >> /vernemq/etc/vernemq.conf

echo "########## End ##########" >> /vernemq/etc/vernemq.conf


# Check configuration file
/vernemq/bin/vernemq config generate 2>&1 > /dev/null | tee /tmp/config.out | grep error

if [ $? -ne 1 ]; then
    echo "configuration error, exit"
    echo "$(cat /tmp/config.out)"
    exit $?
fi

pid=0

# SIGUSR1-handler
siguser1_handler() {
    echo "stopped"
}

# SIGTERM-handler
sigterm_handler() {
    if [ $pid -ne 0 ]; then
        # this will stop the VerneMQ process
        /vernemq/bin/vmq-admin cluster leave node=VerneMQ@$IP_ADDRESS -k > /dev/null
        wait "$pid"
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

# Setup OS signal handlers
trap 'siguser1_handler' SIGUSR1
trap 'sigterm_handler' SIGTERM

# Start VerneMQ
/vernemq/bin/vernemq console -noshell -noinput $@
pid=$(ps aux | grep '[b]eam.smp' | awk '{print $2}')
wait $pid
