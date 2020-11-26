#!/usr/bin/env bash
#
# Copyright (C) 2020 diva.exchange
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author/Maintainer: Konrad Bächler <konrad@diva.exchange>
#

BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
LOG_LEVEL=${LOG_LEVEL:-"trace"}

IP_HTTP_PROXY=${IP_HTTP_PROXY:-} # like 172.20.101.200
PORT_HTTP_PROXY=${PORT_HTTP_PROXY:-} # like 4444
NO_PROXY=${NO_PROXY:-}
if [[ ${IP_HTTP_PROXY} = 'bridge' && PORT_HTTP_PROXY != "" ]]
then
  IP_HTTP_PROXY=`ip route | awk '/default/ { print $3 }'`
fi

# wait for postgres
NAME_CONTAINER_POSTGRES=${NAME_CONTAINER_POSTGRES:-postgres.local.diva.i2p}
IP_POSTGRES=${IP_POSTGRES:-`getent hosts ${NAME_CONTAINER_POSTGRES} | awk '{ print $1 }'`}
PORT_POSTGRES=${PORT_POSTGRES:-5432}
/wait-for-it.sh ${IP_POSTGRES}:${PORT_POSTGRES} -t 30 || exit 1

# create a new peer, if not available
if [[ -f /opt/iroha/data/name.key ]]
then
  NAME_KEY=$(</opt/iroha/data/name.key)
fi

if [[ ! -f /opt/iroha/data/${NAME_KEY}.priv || ! -f /opt/iroha/data/${NAME_KEY}.pub ]]
then
  NAME_KEY=${BLOCKCHAIN_NETWORK}-`pwgen -s -A 12 1`
  /usr/bin/iroha-cli --key_path /opt/iroha/data/ --account_name ${NAME_KEY} --new_account
  chmod 0600 /opt/iroha/data/${NAME_KEY}.priv
  chmod 0644 /opt/iroha/data/${NAME_KEY}.pub
fi
PUB_KEY=$(</opt/iroha/data/${NAME_KEY}.pub)
echo ${NAME_KEY} >/opt/iroha/data/name.key

# networking configuration, disable DNS
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq \
  --listen-address=127.0.1.1 \
  --no-resolv \
  --no-poll \
  --domain-needed \
  --local-service \
  --address=/#/127.0.0.0

# copy the configuration file
cp -r /opt/iroha/data/config-DEFAULT.json /opt/iroha/data/config.json

# set the postgres database name and its IP
if [[ ! -f /opt/iroha/data/iroha-database ]]
then
  NAME_DATABASE="diva_iroha_"`pwgen -A -0 16 1`
  echo ${NAME_DATABASE} >/opt/iroha/data/iroha-database
fi
NAME_DATABASE=$(</opt/iroha/data/iroha-database)
sed -i "s!\$IROHA_DATABASE!iroha"${NAME_DATABASE}"!g ; s!\$IP_POSTGRES!"${IP_POSTGRES}"!g ; s!\$LOG_LEVEL!"${LOG_LEVEL}"!g" \
  /opt/iroha/data/config.json

echo "Blockchain network: ${BLOCKCHAIN_NETWORK}"
echo "Iroha node: ${NAME_KEY}"

# check for a blockstore package to import
[[ -d /opt/iroha/import/ ]] || mkdir -p /opt/iroha/import/ && chmod a+rwx /opt/iroha/import/
[[ -d /opt/iroha/export/ ]] || mkdir -p /opt/iroha/export/
if [[ -f /opt/iroha/import/blockstore.tar.xz ]]
then
  tar -xf /opt/iroha/import/blockstore.tar.xz --directory /opt/iroha/blockstore/
  rm /opt/iroha/import/blockstore.tar.xz
fi

# check for the genesis block
if [[ ! -f /opt/iroha/blockstore/0000000000000001 ]]
then
  if [[ ${BLOCKCHAIN_NETWORK} != "testnet" ]]
  then
    echo "Initialization: using local genesis"
    cp -p /opt/iroha/data/local-genesis/0000000000000001 /opt/iroha/blockstore/0000000000000001
  else
    echo "Initialization: using genesis from testnet.diva.exchange"
    cp -p /opt/iroha/data/testnet-genesis/0000000000000001 /opt/iroha/blockstore/0000000000000001
  fi
fi

# start the Iroha Blockchain
if [[ ${NO_PROXY} != "" ]]
then
  export no_proxy=${NO_PROXY}
  echo "No Proxy: ${no_proxy}"
fi
if [[ ${IP_HTTP_PROXY} != "" && ${PORT_HTTP_PROXY} != "" ]]
then
  export http_proxy=http://${IP_HTTP_PROXY}:${PORT_HTTP_PROXY}
  echo "HTTP Proxy: ${http_proxy}"
fi
cd /opt/iroha/data/
/usr/bin/irohad --config config.json --keypair_name ${NAME_KEY} 2>&1 &
cd /opt/iroha/

# catch SIGINT and SIGTERM
trap "touch /opt/iroha/import/sigterm" SIGTERM SIGINT

# main loop, pack and export blockchain, if changed
MTIME_BS=0
while [[ `pgrep -c irohad` -gt 0 && ! -f /opt/iroha/import/sigterm ]]
do
  sleep 60

  T_BS=`stat -c %Y /opt/iroha/blockstore`
  if [[ ${MTIME_BS} != ${T_BS} ]]
  then
    MTIME_BS=${T_BS}
    ls -1t /opt/iroha/blockstore/ >/opt/iroha/export/lst
    rm -f /opt/iroha/export/blockstore.tar.xz

    tar -c -J -f /opt/iroha/export/blockstore.tar.xz \
      --directory /opt/iroha/blockstore/ \
      --verbatim-files-from --files-from=/opt/iroha/export/lst

    head -1 /opt/iroha/export/lst >/opt/iroha/export/latest
    rm -f /opt/iroha/export/lst
  fi
done

# clean up
rm -f /opt/iroha/import/sigterm
pkill -SIGTERM irohad
while [[ `pgrep -c irohad` -gt 0 ]]
do
  sleep 2
done
