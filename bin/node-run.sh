#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${PROJECT_PATH}/../

# @TODO replace environment variables with arguments, like: run.sh --name=my-iroha-proxy
NAME=${NAME:-iroha-proxy-`date -u +%s`}
IP=${IP:-0.0.0.0}
PORT=${PORT:-10001}

# start the container
docker run \
  -d \
  --env IP=${IP} \
  --env PORT=${PORT} \
  --name=${NAME} \
  divax/iroha:node-proxy
