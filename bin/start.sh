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

# @TODO replace environment variables with arguments, like: start.sh --id=2
ID_INSTANCE=${ID_INSTANCE:-${1:-1}}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
NAME=iroha${ID_INSTANCE}

# bridge IP
IP_IROHA_NODE=`ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+'`
PORT_CONTROL=${PORT_CONTROL:-10002}
PORT_IROHA_PROXY=${PORT_IROHA_PROXY:-10001}

IP_PUBLISHED=${IP_PUBLISHED:-127.19.${ID_INSTANCE}.1}
IP_POSTGRES=${IP_POSTGRES:-${IP_IROHA_NODE}}
PORT_EXPOSE_IROHA_INTERNAL=${PORT_EXPOSE_IROHA_INTERNAL:-10011}
PORT_EXPOSE_IROHA_TORII=${PORT_EXPOSE_IROHA_TORII:-10051}

# start postgres
docker run \
  -d \
  -p ${IP_POSTGRES}:5432:5432 \
  -v iroha-postgres:/var/lib/postgresql/data/ \
  --env POSTGRES_USER=iroha \
  --env POSTGRES_PASSWORD=iroha \
  --network bridge \
  --name iroha-postgres \
  postgres:10 \
  -c 'max_prepared_transactions=100'

# start iroha
docker run \
  -d \
  -p ${IP_PUBLISHED}:${PORT_EXPOSE_IROHA_INTERNAL}:10001 \
  -p ${IP_PUBLISHED}:${PORT_EXPOSE_IROHA_TORII}:50051 \
  -v ${NAME}:/opt/iroha \
  --env ID_INSTANCE=${ID_INSTANCE} \
  --env BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK} \
  --env NAME_KEY=${NAME_KEY} \
  --env IP_PUBLISHED=${IP_PUBLISHED} \
  --env IP_POSTGRES=${IP_POSTGRES} \
  --env IP_IROHA_NODE=${IP_IROHA_NODE} \
  --env PORT_CONTROL=${PORT_CONTROL} \
  --env PORT_IROHA_PROXY=${PORT_IROHA_PROXY} \
  --name ${NAME} \
  --network bridge \
  divax/iroha:latest

echo "Running ${NAME_KEY} on blockchain network ${BLOCKCHAIN_NETWORK}"
