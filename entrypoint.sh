#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

NAME_KEY=${NAME_KEY:-testnet-a}
IP_IROHA_NODE=${IP_IROHA_NODE:?err}

# networking
cat </resolv.conf >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/${NAME_KEY}.diva.local/127.0.0.1 \
  --address=/diva.local/${IP_IROHA_NODE}

if [[ ! -f postgres.lock ]]
then
  #postgres configuration
  cat </postgresql.conf >/etc/postgresql/10/main/postgresql.conf
  cat </pg_hba.conf >/etc/postgresql/10/main/pg_hba.conf
  service postgresql start
  /wait-for-it.sh localhost:5432 -t 30 -s -- /bin/true

  # @TODO password handling -> see also data/config.json
  # set the postgres password to 'iroha'
  su postgres -c "psql -c \"ALTER USER postgres PASSWORD 'iroha';\""

  # create the databases
  su postgres -c "createdb iroha_data"

  touch postgres.lock
else
  service postgresql start
  /wait-for-it.sh localhost:5432 -t 30 -s -- /bin/true
fi

# start the Iroha Blockchain
/wait-for-it.sh ${IP_IROHA_NODE}:10001 -t 600 -s -- /usr/bin/irohad \
  --config /opt/iroha/data/config.json --keypair_name ${NAME_KEY}
