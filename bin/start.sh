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

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/../
cd ${PROJECT_PATH}

# @TODO replace environment variables with arguments, like: run.sh --id=2
ID_INSTANCE=${ID_INSTANCE:-${1:-1}}
BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
NAME=iroha${ID_INSTANCE}

# bridge IP
IP_IROHA_NODE=`ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+'`
IP_PUBLISHED=${IP_PUBLISHED:-127.19.${ID_INSTANCE}.1}

# start the container
docker run \
  -d \
  -p ${IP_PUBLISHED}:5432:5432 \
  -p ${IP_PUBLISHED}:10001:10001 \
  -p ${IP_PUBLISHED}:50051:50051 \
  -v ${NAME}:/opt/iroha \
  --env BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK} \
  --env NAME_KEY=${NAME_KEY} \
  --env IP_PUBLISHED=${IP_PUBLISHED} \
  --env IP_IROHA_NODE=${IP_IROHA_NODE} \
  --name ${NAME} \
  --network bridge \
  divax/iroha:latest

echo "Running ${NAME_KEY} on blockchain network ${BLOCKCHAIN_NETWORK}"
