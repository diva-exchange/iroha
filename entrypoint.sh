#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

NAME_KEY=${NAME_KEY:-"-"}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:?err}
IP_IROHA_NODE=${IP_IROHA_NODE:?err}
TYPE=${TYPE:-"P2P"}
IP=${IP:-`hostname -I | cut -d' ' -f1`}

# create a new peer, if not available
if [[ ! -f ${NAME_KEY}.priv || ! -f ${NAME_KEY}.pub ]]
then
  NAME_KEY=${BLOCKCHAIN_NETWORK}-`pwgen -s -A 12 1`
  /usr/bin/iroha-cli --account_name ${NAME_KEY} --new_account
  chmod 0600 ${NAME_KEY}.priv
  chmod 0644 ${NAME_KEY}.pub
fi

echo "Starting Iroha Node ${NAME_KEY} on ${IP}"

# networking configuration
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/${NAME_KEY}.diva.local/127.0.0.1 \
  --address=/diva.local/${IP_IROHA_NODE}

# wait for a potential proxy and register at it
/wait-for-it.sh ${IP_IROHA_NODE}:10002 -t 30 -s -- curl -f -I \
  http://${IP_IROHA_NODE}:10002/register?ip=${IP}\&room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY}\

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

# wait for a potential proxy
/wait-for-it.sh ${IP_IROHA_NODE}:10001 -t 30 -s -- /bin/true

# start the Iroha Blockchain
/usr/bin/irohad --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY} 2>&1 &

# relax - wait until iroha database gets created
sleep 10

# create a read-only user: "explorer", password "explorer" - a public access to the world state of Iroha
su postgres -c "psql -d iroha_data -f /create-read-only-explorer.sql"

# catch SIGINT and SIGTERM
trap "\
  curl -f -I \
    http://${IP_IROHA_NODE}:10002/close?ip=${IP}\&room=${BLOCKCHAIN_NETWORK}\&ident=${NAME_KEY} ;\
  pkill -SIGTERM irohad ;\
  service postgresql stop ;\
  sleep 5 ;\
  exit 0" SIGTERM SIGINT

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
