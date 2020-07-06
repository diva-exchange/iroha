#!/usr/bin/env bash

set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${PROJECT_PATH}/../

docker build -f Dockerfile-Genesis --no-cache --force-rm -t divax/iroha-genesis:latest .

docker network create iroha-genesis-network

docker run \
  --name postgres_genesis \
  --volume postgres_genesis:/var/lib/postgresql/data/ \
  -e POSTGRES_USER=postgres_genesis \
  -e POSTGRES_PASSWORD=postgres_genesis \
  --network=iroha-genesis-network \
  -d \
  postgres:10 \
  -c 'max_prepared_transactions=100'

docker run \
  -d \
  --name iroha_genesis \
  --volume iroha_genesis:/opt/iroha/ \
  --network=iroha-genesis-network \
  divax/iroha-genesis:latest

# wait until the genesis block and the new keys have been created
sleep 10

# copy genesis block
cp -f /var/lib/docker/volumes/iroha_genesis/_data/blockstore/0000000000000001 \
  blockstore/0000000000000001
chown --reference blockstore blockstore/0000000000000001

# copy keys
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/diva@testnet.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/testnet-a.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/testnet-b.* data/
cp -f /var/lib/docker/volumes/iroha_genesis/_data/data/testnet-c.* data/
chown --reference data data/*
chmod 0600 data/*.priv
chmod 0644 data/*.pub

docker stop postgres_genesis
docker rm postgres_genesis
docker volume rm postgres_genesis
docker stop iroha_genesis
docker rm iroha_genesis
docker volume rm iroha_genesis
docker network rm iroha-genesis-network
docker rmi divax/iroha-genesis:latest
