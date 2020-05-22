#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#
set -e

# optional
IDENT_INSTANCE=${IDENT_INSTANCE:-0}

# derived
LOCAL_IROHA_NODE_KEY=holodeck${IDENT_INSTANCE:?err}

# @TODO improve isolation? iptables not possible within docker?
# isolated networking
echo "nameserver 127.0.1.1" >/etc/resolv.conf
cat </dnsmasq.conf >/etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/#/127.0.0.1

# proxying iroha traffic
su node -c "cd /opt/iroha/ && node -r esm ./app/proxy-out.js &"

echo key: ${LOCAL_IROHA_NODE_KEY}

# remove unused keys
mv -f ${LOCAL_IROHA_NODE_KEY}* ../
rm -f holodeck*
mv -f ../${LOCAL_IROHA_NODE_KEY}* ./

#postgres configuration
cat </postgresql.conf >/etc/postgresql/10/main/postgresql.conf
service postgresql start
/wait-for-it.sh localhost:5432 -t 30 -s --

# set the postgres password to 'iroha'
# this should be NO security issue, because
# - the access to the database is from within the container only
# - all data on the database is public and only a mirror (to increase efficiency and performance) of the blockchain
su postgres -c "psql -c \"ALTER USER postgres PASSWORD 'iroha';\""

# start iroha
irohad \
  --config config.json \
  --keypair_name ${LOCAL_IROHA_NODE_KEY}
