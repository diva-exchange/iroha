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

IP_ORIGIN=`hostname -I | cut -d' ' -f1`
IP_PUBLISHED=${IP_PUBLISHED:?IP_PUBLISHED undefined}
IP_IROHA_PROXY=${IP_IROHA_PROXY:-}

if [[ ${IP_IROHA_PROXY} = 'bridge' ]]
then
  IP_IROHA_PROXY=`ip route | awk '/default/ { print $3 }'`
else
  IP_IROHA_PROXY=${IP_IROHA_PROXY:-127.0.0.0} # default: 127.0.0.0, non-reachable
fi
PORT_IROHA_PROXY=${PORT_IROHA_PROXY:-19011}
PORT_CONTROL=${PORT_CONTROL:-19012}

# wait for postgres
IP_POSTGRES=`getent hosts iroha-postgres | awk '{ print $1 }'`
/wait-for-it.sh ${IP_POSTGRES}:5432 -t 30 || exit 1

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
dnsmasq -RnD -a 127.0.1.1 \
  --local-service \
  --address=/${NAME_KEY}.diva/127.0.0.1 \
  --address=/diva/${IP_IROHA_PROXY}

if [[ ${TYPE} = 'P2P' || ${TYPE} = 'I2P' ]]
then
  echo "Related Iroha Proxy ${IP_IROHA_PROXY}"
  # wait for a potential proxy
  /wait-for-it.sh ${IP_IROHA_PROXY}:${PORT_IROHA_PROXY} -t 600
fi

if [[ ${TYPE} = 'P2P' ]]
then
  # register at the proxy
  URL="http://${IP_IROHA_PROXY}:${PORT_CONTROL}/register"
  URL="${URL}?ip_origin=${IP_ORIGIN}&ip_iroha=${IP_PUBLISHED}&room=${BLOCKCHAIN_NETWORK}&ident=${NAME_KEY}"
  curl --silent -f -I ${URL}
fi

# set the postgres database name and its IP
if [[ ${TYPE} = 'I2P' ]]
then
  cp /opt/iroha/data/config-I2P.json /opt/iroha/data/config.json
else
  cp /opt/iroha/data/config-P2P.json /opt/iroha/data/config.json
fi
if [[ ! -f /iroha-database.done ]]
then
  NAME_DATABASE="iroha"`pwgen -A -0 16 1`
  echo ${NAME_DATABASE} >/iroha-database.done
fi
NAME_DATABASE=$(</iroha-database.done)
sed -i "s!\$IROHA_DATABASE!iroha"${NAME_DATABASE}"!g ; s!\$IP_POSTGRES!"${IP_POSTGRES}"!g" \
  /opt/iroha/data/config.json

# catch SIGINT and SIGTERM
TRAP=" ;"
if [[ ${TYPE} = 'P2P' ]]
then
  URL="http://${IP_IROHA_PROXY}:${PORT_CONTROL}/close"
  URL=${URL}'?ip_origin=${IP_ORIGIN}\&ip_iroha=${IP_PUBLISHED}\&room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY}'
  TRAP="curl --silent -f -I ${URL} ;"
fi
trap "${TRAP}\
  sleep 5 ;\
  exit 0" SIGTERM SIGINT

echo "Blockchain network: ${BLOCKCHAIN_NETWORK}"
echo "Iroha node: ${NAME_KEY}"
echo "Published IP: ${IP_PUBLISHED}"

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config.json --keypair_name ${NAME_KEY} 2>&1 &

if [[ ${TYPE} = 'P2P' ]]
then
  # add peer
  URL="http://${IP_IROHA_PROXY}:${PORT_CONTROL}/peer/add"
  URL="${URL}?name=${NAME_KEY}&key=${PUB_KEY}"
  curl --silent -f -I ${URL}
fi

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
