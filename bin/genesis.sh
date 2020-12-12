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

TAG=${TAG:-burrow}
docker build -f Dockerfile-Genesis --no-cache --force-rm -t divax/iroha-genesis:${TAG} .

docker network create iroha-genesis-network

docker run \
  --name postgres_genesis \
  --volume postgres_genesis:/var/lib/postgresql/data/ \
  -e POSTGRES_USER=postgres_genesis \
  -e POSTGRES_PASSWORD=postgres_genesis \
  --network=iroha-genesis-network \
  -d \
  postgres:alpine \
  --max_prepared_transactions=0

# --max_prepared_transactions=100

docker run \
  -d \
  --name iroha_genesis \
  --volume iroha_genesis:/opt/iroha/ \
  --network=iroha-genesis-network \
  divax/iroha-genesis:${TAG}

# wait until the genesis block and the new keys have been created
sleep 10

# copy genesis block
cp -f /var/lib/docker/volumes/iroha_genesis/_data/blockstore/0000000000000001 \
  data/local-genesis/0000000000000001
chown --reference data data/local-genesis/0000000000000001

# copy keys
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/diva@testnet.diva.i2p.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n1.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n2.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n3.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n4.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n5.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n6.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/n7.* data/
chown --reference data data/*

docker stop postgres_genesis
docker rm postgres_genesis
docker volume rm postgres_genesis
docker stop iroha_genesis
docker rm iroha_genesis
docker volume rm iroha_genesis
docker network rm iroha-genesis-network
docker rmi divax/iroha-genesis:${TAG}

${PROJECT_PATH}bin/build.sh
