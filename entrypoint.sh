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

TYPE=${TYPE:-"P2P"}
ID_INSTANCE=${ID_INSTANCE:?err}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
IP_ORIGIN=`hostname -I | cut -d' ' -f1`
IP_PUBLISHED=${IP_PUBLISHED:-127.19.${ID_INSTANCE}.1}

IP_POSTGRES=${IP_POSTGRES:?err}
IP_IROHA_NODE=${IP_IROHA_NODE:-127.0.0.0}
PORT_CONTROL=${PORT_CONTROL:-10002}
PORT_IROHA_PROXY=${PORT_IROHA_PROXY:-10001}

# wait for postgres
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

echo "Starting Iroha ${NAME_KEY} on published IP ${IP_PUBLISHED}"
echo "Related Iroha Node ${IP_IROHA_NODE}"

# networking configuration
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -RnD -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/postgres.diva.local/${IP_POSTGRES} \
  --address=/${NAME_KEY}.diva.local/127.0.0.1 \
  --address=/diva.local/${IP_IROHA_NODE}

# wait for the control port of a potential proxy and register
/wait-for-it.sh ${IP_IROHA_NODE}:${PORT_CONTROL} -t 10
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/register"
URL="${URL}?ip_origin=${IP_ORIGIN}&ip_iroha=${IP_PUBLISHED}&room=${BLOCKCHAIN_NETWORK}&ident=${NAME_KEY}"
curl --silent -f -I ${URL}

# wait for a potential proxy
/wait-for-it.sh ${IP_IROHA_NODE}:${PORT_IROHA_PROXY} -t 10

# set the postgres database name
if [[ ! -f /iroha-database.done ]]
then
  sed -i "s/\$IROHA_DATABASE/iroha${ID_INSTANCE}/" /opt/iroha/data/config-${TYPE}.json
  touch /iroha-database.done
fi

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY} 2>&1 &

# catch SIGINT and SIGTERM
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/close"
URL=${URL}'?ip_origin=${IP_ORIGIN}\&ip_iroha=${IP_PUBLISHED}\&room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY}'
trap "curl --silent -f -I ${URL} ;\
  pkill -SIGTERM irohad ;\
  sleep 5 ;\
  exit 0" SIGTERM SIGINT

# add peer
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/peer/add"
URL="${URL}?name=${NAME_KEY}&key=${PUB_KEY}"
curl --silent -f -I ${URL}

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
