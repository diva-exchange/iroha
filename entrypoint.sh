#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

NAME_KEY=${NAME_KEY:-testnet-a}
IP_IROHA_NODE=${IP_IROHA_NODE:?err}
TYPE=${TYPE:-P2P}

# networking configuration
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/${NAME_KEY}.diva.local/127.0.0.1 \
  --address=/diva.local/${IP_IROHA_NODE}

# postgres configuration
cat </postgresql.conf >/etc/postgresql/10/main/postgresql.conf
cat </pg_hba.conf >/etc/postgresql/10/main/pg_hba.conf

service postgresql start
/wait-for-it.sh localhost:5432 -t 30 -s -- /bin/true

if [[ ! -f /iroha-password.done ]]
then
  # update the postgres password
  IROHA_PASSWORD=`pwgen -s 32 1`
  su postgres -c "psql -c \"ALTER USER postgres PASSWORD '${IROHA_PASSWORD}';\""
  sed -i "s/\$POSTGRES_PASSWORD/${IROHA_PASSWORD}/" /opt/iroha/data/config-${TYPE}.json
  IROHA_PASSWORD=""
  touch /iroha-password.done
fi

# relax - wait until iroha database gets created
sleep 30

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY} 2>&1 &

# relax - wait until iroha database gets created
sleep 10

# create a read-only user: "explorer", password "explorer" - a public access to the world state of Iroha
su postgres -c "psql -d iroha_data -f /create-read-only-explorer.sql"

# catch SIGINT and SIGTERM
trap "pkill -SIGTERM irohad ; exit 0" SIGTERM SIGINT

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
