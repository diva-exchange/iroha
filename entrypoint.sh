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

if [[ ! -f postgres.lock ]]
then
  service postgresql start
  /wait-for-it.sh localhost:5432 -t 30 -s -- /bin/true

  # create the database
  su postgres -c "createdb iroha_data"

  # create a read-only user: "explorer", password "explorer" - a public access to the world state of Iroha
  su postgres -c "psql -f /create-read-only-explorer.sql"

  # set the postgres password
  pwgen -s 32 1 >iroha.passwd
  su postgres -c "psql -c \"ALTER USER postgres PASSWORD '$(<iroha.passwd)';\""
  sed "s/\$POSTGRES_PASSWORD/$(<iroha.passwd)/" /opt/iroha/data/config-${TYPE}.json \
    >/opt/iroha/data/config-${TYPE}.json
  rm iroha.passwd

  touch postgres.lock
else
  service postgresql start
  /wait-for-it.sh localhost:5432 -t 30 -s -- /bin/true
fi

# relax
sleep 30

# start the Iroha Blockchain
/wait-for-it.sh ${IP_IROHA_NODE}:10001 -t 30 -s -- /usr/bin/irohad \
  --config /opt/iroha/data/config-${TYPE}.json --keypair_name ${NAME_KEY}
