#!/usr/bin/env bash

set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${PROJECT_PATH}/../

# persistent data storage
docker volume create iroha0

# start the container
docker run -d --name=iroha0 --mount type=volume,src=iroha0,dst=/opt/iroha/data/ diva/iroha:latest
