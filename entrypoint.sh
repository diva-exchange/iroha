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

NAME_KEY=${NAME_KEY:?err}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:?err}
IP_PUBLISHED=${IP_PUBLISHED:?err}
IP_IROHA_NODE=${IP_IROHA_NODE:?err}
PORT_CONTROL=${PORT_CONTROL:-10002}
TYPE=${TYPE:-"P2P"}

# create a new peer, if not available
if [[ ! -f ${NAME_KEY}.priv || ! -f ${NAME_KEY}.pub ]]
then
  NAME_KEY=${BLOCKCHAIN_NETWORK}-`pwgen -s -A 12 1`
  /usr/bin/iroha-cli --account_name ${NAME_KEY} --new_account
  chmod 0600 ${NAME_KEY}.priv
  chmod 0644 ${NAME_KEY}.pub
fi

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

# register at proxy
URL="http://${IP_IROHA_NODE}:${PORT_CONTROL}/register"
URL="${URL}?ip_iroha=${IP_PUBLISHED}&room=${BLOCKCHAIN_NETWORK}&ident=${NAME_KEY}"

curl --silent -f -I ${URL}

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

# wait for a potential proxy
/wait-for-it.sh ${IP_IROHA_NODE}:10001 -t 10

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY} 2>&1 &

# catch SIGINT and SIGTERM
trap "\
  curl --silent -f -I \
    http://${IP_IROHA_NODE}:${PORT_CONTROL}/close?room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY} ;\
  pkill -SIGTERM irohad ;\
  service postgresql stop ;\
  sleep 5 ;\
  exit 0" SIGTERM SIGINT

# relax - wait until iroha database gets created
sleep 10

# create a read-only user: "explorer", password "explorer" - a public access to the world state of Iroha
su postgres -c "psql -d iroha_data -f /create-read-only-explorer.sql"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
