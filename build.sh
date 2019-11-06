#!/usr/bin/env bash

set -e

export PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $PROJECT_PATH

IDENT_INSTANCE=0
export IDENT_INSTANCE

set -a
source iroha-diva.env
envsubst < template.docker-compose.yml > /tmp/docker-compose.yml
set +a

docker-compose -f /tmp/docker-compose.yml build --no-cache --force-rm
rm /tmp/docker-compose.yml

# build hangout
cd ../hangout/ && ./build.sh
