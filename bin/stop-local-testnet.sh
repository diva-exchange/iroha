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
NAME_EXPLORER=${NAME_EXPLORER:-explorer.${DOMAIN}}

# explorer
echo "Stopping ${NAME_EXPLORER}..."
[[ `docker ps | fgrep ${NAME_EXPLORER}` ]] && docker stop ${NAME_EXPLORER} >/dev/null
[[ `docker ps -a | fgrep ${NAME_EXPLORER}` ]] && docker rm ${NAME_EXPLORER} >/dev/null

# postgres and iroha container
for (( t=1; t<=${NODES}; t++ ))
do
  echo "Stopping n${t}.${DOMAIN}..."
  [[ `docker ps | fgrep n${t}.${DOMAIN}` ]] && docker stop n${t}.${DOMAIN} >/dev/null
  echo "Stopping n${t}.db.${DOMAIN}..."
  [[ `docker ps | fgrep n${t}.db.${DOMAIN}` ]] && docker stop n${t}.db.${DOMAIN} >/dev/null
  [[ `docker ps -a | fgrep n${t}.${DOMAIN}` ]] && docker rm n${t}.${DOMAIN} >/dev/null
  [[ `docker ps -a | fgrep n${t}.db.${DOMAIN}` ]] && docker rm n${t}.db.${DOMAIN} >/dev/null
  [[ `docker volume ls | fgrep n${t}.db.${DOMAIN}` ]] && docker volume rm n${t}.db.${DOMAIN} >/dev/null
done

# keystore
echo "Stopping ${NAME_KEYSTORE}..."
[[ `docker ps | fgrep ${NAME_KEYSTORE}` ]] && docker stop ${NAME_KEYSTORE} >/dev/null
[[ `docker ps -a | fgrep ${NAME_KEYSTORE}` ]] && docker rm ${NAME_KEYSTORE} >/dev/null

#network
echo "Removing network ${NAME_NETWORK}..."
[[ `docker network ls | fgrep ${NAME_NETWORK}` ]] && docker network rm ${NAME_NETWORK} >/dev/null
