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
# -e  Exit immediately if a simple command exits with a non-zero status
set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/../
cd ${PROJECT_PATH}

NODES=${NODES:-7}
DOMAIN=${DOMAIN:-testnet.diva.i2p}
NAME_NETWORK=${NAME_NETWORK:-network.${DOMAIN}}
NAME_KEYSTORE=${NAME_KEYSTORE:-keystore.${DOMAIN}}
IP_KEYSTORE=172.29.101.2
NAME_EXPLORER=${NAME_EXPLORER:-explorer.${DOMAIN}}
IP_EXPLORER=172.29.101.3

# network
echo "Creating network ${NAME_NETWORK}..."
if [[ ! `docker network ls | fgrep ${NAME_NETWORK}` ]]
then
  docker network create \
    --driver bridge \
    --ipam-driver default \
    --subnet 172.29.101.0/24 \
    ${NAME_NETWORK} \
    >/dev/null
fi

# keystore
echo "Starting ${NAME_KEYSTORE}..."
docker run \
  --detach \
  --name ${NAME_KEYSTORE} \
  --restart unless-stopped \
  --stop-timeout 5 \
  --network ${NAME_NETWORK} \
  --ip ${IP_KEYSTORE} \
  --volume ${NAME_KEYSTORE}:/home/ \
  --tty \
  alpine:latest \
  >/dev/null

docker exec ${NAME_KEYSTORE} /bin/sh -c "mkdir -p /home/i2p ; mkdir -p /home/iroha"

# postgres and iroha
IP_IROHA_START=120
ADD_HOSTS=""
NO_PROXY=""
for (( t=1; t<=${NODES}; t++ ))
do
  IP_IROHA=172.29.101.$(( ${IP_IROHA_START} + ${t} ))
  ADD_HOSTS="${ADD_HOSTS}--add-host n${t}.${DOMAIN}:${IP_IROHA}"
  [[ ${t} -lt ${NODES} ]] && ADD_HOSTS="${ADD_HOSTS} "
  NO_PROXY="${NO_PROXY}n${t}.${DOMAIN}:${IP_IROHA}"
  [[ ${t} -lt ${NODES} ]] && NO_PROXY="${NO_PROXY},"
done
echo "ADD_HOSTS: ${ADD_HOSTS}"
echo "NO_PROXY: ${NO_PROXY}"

IP_POSTGRES_START=20
for (( t=1; t<=${NODES}; t++ ))
do
  echo "Starting n${t}.db.${DOMAIN}..."
  IP_POSTGRES=172.29.101.$(( ${IP_POSTGRES_START} + ${t} ))
  docker run \
    --detach \
    --name n${t}.db.${DOMAIN} \
    --restart unless-stopped \
    --stop-timeout 5 \
    --network ${NAME_NETWORK} \
    --ip ${IP_POSTGRES} \
    --env POSTGRES_DATABASE=iroha \
    --env POSTGRES_USER=iroha \
    --env POSTGRES_PASSWORD=iroha \
    --volume n${t}.db.${DOMAIN}:/var/lib/postgresql/data/ \
    postgres:10-alpine \
    >/dev/null

  echo "Starting n${t}.${DOMAIN}..."
  IP_IROHA=172.29.101.$(( ${IP_IROHA_START} + ${t} ))
  docker run \
    ${ADD_HOSTS} \
    --detach \
    --name n${t}.${DOMAIN} \
    --restart unless-stopped \
    --stop-timeout 5 \
    --network ${NAME_NETWORK} \
    --ip ${IP_IROHA} \
    --env IP_POSTGRES=${IP_POSTGRES} \
    --env NAME_DATABASE=iroha \
    --env NAME_PEER=n${t} \
    --env BLOCKCHAIN_NETWORK=local \
    --env NO_PROXY=${NO_PROXY} \
    --volume n${t}.${DOMAIN}:/opt/iroha/ \
    divax/iroha:latest \
    >/dev/null
done

# explorer
echo "Starting ${NAME_EXPLORER}..."
docker run \
  --detach \
  --name ${NAME_EXPLORER} \
  --restart unless-stopped \
  --stop-timeout 5 \
  --network ${NAME_NETWORK} \
  --ip ${IP_EXPLORER} \
  --env IP_EXPLORER=0.0.0.0 \
  --env PORT_EXPLORER=3920 \
  --env PATH_IROHA=/tmp/iroha/ \
  --volume n1.${DOMAIN}:/tmp/iroha/:ro \
  divax/iroha-explorer:latest \
  >/dev/null
