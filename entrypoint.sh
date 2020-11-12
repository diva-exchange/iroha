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

TYPE=${TYPE:-"NONE"}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
LOG_LEVEL=${LOG_LEVEL:-"info"}

IP_IROHA_API=${IP_IROHA_API:-}
if [[ ${IP_IROHA_API} = 'bridge' ]]
then
  IP_IROHA_API=`ip route | awk '/default/ { print $3 }'`
else
  IP_IROHA_API=${IP_IROHA_API:-127.0.0.0} # default: 127.0.0.0, non-reachable
fi
PORT_IROHA_API=${PORT_IROHA_API:-19012}

IP_HTTP_PROXY=${IP_HTTP_PROXY:-} # like 172.20.101.1
PORT_HTTP_PROXY=${PORT_HTTP_PROXY:-} # like 4544

# wait for postgres and chill a bit
IP_POSTGRES=`getent hosts iroha-postgres | awk '{ print $1 }'`
/wait-for-it.sh ${IP_POSTGRES}:5432 -t 30 || exit 1
sleep 5

# create a new peer, if not available
if [[ -f name.key ]]
then
  NAME_KEY=$(<name.key)
fi

if [[ ! -f ${NAME_KEY}.priv || ! -f ${NAME_KEY}.pub ]]
then
  NAME_KEY=${BLOCKCHAIN_NETWORK}-`pwgen -s -A 12 1`
  /usr/bin/iroha-cli --account_name ${NAME_KEY} --new_account
  chmod 0644 ${NAME_KEY}.priv
  chmod 0644 ${NAME_KEY}.pub
fi
PUB_KEY=$(<${NAME_KEY}.pub)
echo ${NAME_KEY} >name.key

# networking configuration
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq \
  --listen-address=127.0.1.1 \
  --no-resolv \
  --no-poll \
  --domain-needed \
  --local-service \
  --address=/#/127.0.0.0 # void

if [[ ${TYPE} = 'I2P' ]]
then
  echo "Related Iroha API ${IP_IROHA_API}"
  # wait for the API
  /wait-for-it.sh ${IP_IROHA_API}:${PORT_IROHA_API} -t 600 || exit 2

  # copy the configuration file
  cp -r /opt/iroha/data/config-I2P.json /opt/iroha/data/config.json
else
  # copy the configuration file
  cp -r /opt/iroha/data/config-DEFAULT.json /opt/iroha/data/config.json
fi

# set the postgres database name and its IP
if [[ ! -f /iroha-database.done ]]
then
  NAME_DATABASE="diva_iroha_"`pwgen -A -0 16 1`
  echo ${NAME_DATABASE} >/iroha-database.done
fi
NAME_DATABASE=$(</iroha-database.done)
sed -i "s!\$IROHA_DATABASE!iroha"${NAME_DATABASE}"!g ; s!\$IP_POSTGRES!"${IP_POSTGRES}"!g ; s!\$LOG_LEVEL!"${LOG_LEVEL}"!g" \
  /opt/iroha/data/config.json

echo "Blockchain network: ${BLOCKCHAIN_NETWORK}"
echo "Iroha node: ${NAME_KEY}"

# start the Iroha Blockchain
if [[ ${TYPE} = 'I2P' && ${IP_HTTP_PROXY} != "" && ${PORT_HTTP_PROXY} != "" ]]
then
  export http_proxy=http://${IP_HTTP_PROXY}:${PORT_HTTP_PROXY}
fi
/usr/bin/irohad --config /opt/iroha/data/config.json --keypair_name ${NAME_KEY} 2>&1 &

# catch SIGINT and SIGTERM
trap "pkill -SIGTERM irohad ; sleep 5 ; exit 0" SIGTERM SIGINT

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
