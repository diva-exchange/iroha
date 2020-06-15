#!/usr/bin/env bash

set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${PROJECT_PATH}/../

# persistent data storage
docker volume create iroha

# start the container
docker run -d -p 25432:5432 -p 50151:50051 --name=iroha -v iroha:/opt/iroha/data divax/iroha:latest
