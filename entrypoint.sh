#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#
set -e

# mandatory
IDENT_INSTANCE=${IDENT_INSTANCE:?err}
POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME:?err}
POSTGRES_IP=${POSTGRES_IP:?err}
POSTGRES_USER=${POSTGRES_USER:?err}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:?err}
CONST_POSTGRES_DOCKER_PORT=${CONST_POSTGRES_DOCKER_PORT:?err}
IROHA_NAME_CONFIG=${IROHA_NAME_CONFIG:?err}
IROHA_IP=${IROHA_IP:?err}
DIVA_IP=${DIVA_IP:?err}
CONST_DIVA_BACKEND_UTP_PROXY_PORT=${CONST_DIVA_BACKEND_UTP_PROXY_PORT:?err}

LOCAL_IROHA_NODE_KEY=holodeck${IDENT_INSTANCE:?err}

# isolated networking
echo "nameserver 127.0.1.1" > /etc/resolv.conf
/bin/cp -f /dnsmasq.conf /etc/dnsmasq.conf
dnsmasq -a 127.0.1.1 \
  --no-hosts \
  --local-service \
  --address=/holodeck0.diva.local/172.18.0.12 \
  --address=/holodeck1.diva.local/172.18.1.12 \
  --address=/holodeck2.diva.local/172.18.2.12 \
  --address=/${POSTGRES_CONTAINER_NAME}/${POSTGRES_IP} \
  --address=/#/127.0.0.1

# replace the POSTGRES variables in the config file
sed -i "s/\$POSTGRES_CONTAINER_NAME/${POSTGRES_CONTAINER_NAME}/g" ${IROHA_NAME_CONFIG}
sed -i "s/\$POSTGRES_USER/${POSTGRES_USER}/g" ${IROHA_NAME_CONFIG}
sed -i "s/\$POSTGRES_PASSWORD/${POSTGRES_PASSWORD}/g" ${IROHA_NAME_CONFIG}

echo key: ${LOCAL_IROHA_NODE_KEY}
echo postgres: ${POSTGRES_CONTAINER_NAME}:${CONST_POSTGRES_DOCKER_PORT}

# remove unused keys
mv -f ${LOCAL_IROHA_NODE_KEY}* ../
rm -f holodeck*
mv -f ../${LOCAL_IROHA_NODE_KEY}* ./

/wait-for-it.sh ${POSTGRES_CONTAINER_NAME}:${CONST_POSTGRES_DOCKER_PORT} -t 30 -s -- \
  && sleep 5 \
  && irohad \
    --config ${IROHA_NAME_CONFIG} \
    --keypair_name ${LOCAL_IROHA_NODE_KEY}
