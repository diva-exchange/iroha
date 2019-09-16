#!/usr/bin/env bash

set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $PROJECT_PATH

docker build -f Dockerfile-Genesis --no-cache --force-rm -t diva/iroha-genesis:1.1.0 .

docker network create iroha-genesis-network

docker run \
  --name postgres_genesis \
  --volume postgres_genesis:/var/lib/postgresql/data/ \
  -e POSTGRES_USER=postgres_genesis \
  -e POSTGRES_PASSWORD=postgres_genesis \
  --network=iroha-genesis-network \
  -d \
  postgres:9.5 \
  -c 'max_prepared_transactions=100'

docker run \
  -d \
  --name iroha_genesis \
  --volume iroha_genesis:/opt/iroha/ \
  --network=iroha-genesis-network \
  diva/iroha-genesis:1.1.0

# wait until the genesis block got created
sleep 10

cp -f /var/lib/docker/volumes/iroha_genesis/_data/blockstore/0000000000000001 \
  /home/konrad/workspace/kopanyo/diva/iroha/blockstore/0000000000000001
chown konrad:konrad /home/konrad/workspace/kopanyo/diva/iroha/blockstore/0000000000000001

docker stop postgres_genesis
docker rm postgres_genesis
docker volume rm postgres_genesis
docker stop iroha_genesis
docker rm iroha_genesis
docker volume rm iroha_genesis
docker network rm iroha-genesis-network

