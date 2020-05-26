#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#
set -e

# networking
echo "nameserver 127.0.1.1" >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/#/127.0.0.1

#postgres configuration
cat </postgresql.conf >/etc/postgresql/10/main/postgresql.conf
cat </pg_hba.conf >/etc/postgresql/10/main/pg_hba.conf
service postgresql start
/wait-for-it.sh localhost:5432 -t 30 -s --

# set the postgres password to 'iroha'
# this shouldn't be a security issue, because
# - the access to the database is from within the container only
# - all data on the database is public and only a mirror (to increase efficiency and performance) of the blockchain
su postgres -c "psql -c \"ALTER USER postgres PASSWORD 'iroha';\""

# create the databases
su postgres -c "createdb iroha_data0 && createdb iroha_data1 && createdb iroha_data2"

# start iroha
/usr/bin/irohad --config config0.json --keypair_name holodeck0 2>&1 &
sleep 5
/usr/bin/irohad --config config1.json --keypair_name holodeck1 2>&1 &
sleep 5
/usr/bin/irohad --config config2.json --keypair_name holodeck2 2>&1 &

while sleep 60; do
  ps aux | grep irohad | grep -q -v grep
  PROCESS_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  if [ $PROCESS_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
