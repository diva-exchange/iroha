#!/usr/bin/env bash
#
# Copyright (C) 2020 diva.exchange
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Author/Maintainer: Konrad Bächler <konrad@diva.exchange>
#

TYPE=${TYPE:-"P2P"}
NAME_KEY=${NAME_KEY:?err}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:?err}
IP_ORIGIN=`hostname -I | cut -d' ' -f1`
IP_PUBLISHED=${IP_PUBLISHED:?err}
IP_IROHA_NODE=${IP_IROHA_NODE:?err}
PORT_CONTROL=${PORT_CONTROL:?err}
PORT_IROHA_PROXY=${PORT_IROHA_PROXY:?err}

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
  --address=/${NAME_KEY}.diva.local/127.0.0.1 \
  --address=/diva.local/${IP_IROHA_NODE}

# wait for the control port of a potential proxy
/wait-for-it.sh ${IP_IROHA_NODE}:${PORT_CONTROL} -t 10

# register at proxy
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/register"
URL="${URL}?ip_origin=${IP_ORIGIN}&ip_iroha=${IP_PUBLISHED}&room=${BLOCKCHAIN_NETWORK}&ident=${NAME_KEY}"
curl --silent -f -I ${URL}

# wait for a potential proxy
/wait-for-it.sh ${IP_IROHA_NODE}:${PORT_IROHA_PROXY} -t 10

# postgres configuration
cat </postgresql.conf >/etc/postgresql/10/main/postgresql.conf
cat </pg_hba.conf >/etc/postgresql/10/main/pg_hba.conf

service postgresql start
/wait-for-it.sh localhost:5432 -t 10 || (echo "Postgres failed to start" ; exit 1)

if [[ ! -f /iroha-password.done ]]
then
  # update the postgres password
  IROHA_PASSWORD=`pwgen -s 32 1`
  su postgres -c "psql -c \"ALTER USER postgres PASSWORD '${IROHA_PASSWORD}';\""
  sed -i "s/\$POSTGRES_PASSWORD/${IROHA_PASSWORD}/" /opt/iroha/data/config-${TYPE}.json
  IROHA_PASSWORD=""
  touch /iroha-password.done
fi

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY} 2>&1 &

# catch SIGINT and SIGTERM
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/close"
URL=${URL}'?ip_origin=${IP_ORIGIN}\&ip_iroha=${IP_PUBLISHED}\&room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY}'
trap "curl --silent -f -I ${URL} ;\
  pkill -SIGTERM irohad ;\
  service postgresql stop ;\
  sleep 5 ;\
  exit 0" SIGTERM SIGINT

# relax - wait until iroha database gets created
sleep 10

# create a read-only user: "explorer", password "explorer" - a public access to the world state of Iroha
su postgres -c "psql -d iroha_data -f /create-read-only-explorer.sql"

# add peer
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/peer/add"
URL="${URL}?name=${NAME_KEY}&key=${PUB_KEY}"
curl --silent -f -I ${URL}

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
