#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${PROJECT_PATH}/../

# @TODO replace environment variables with arguments, like: run.sh --name=my-ip2d
IP_IROHA_NODE=${IP_IROHA_NODE:?err}
PORT_POSTGRES=${PORT_POSTGRES:-5032}
PORT_INTERNAL=${PORT_INTERNAL:-10001}
PORT_TORII=${PORT_TORII:-50051}

NAME_KEY=${NAME_KEY:-testnet-a}
NAME=${NAME:-iroha-${NAME_KEY}}
NAME_VOLUME=${NAME_VOLUME:-${NAME}}

# start the container
docker run \
  -d \
  -p 127.0.0.1:${PORT_POSTGRES}:5432 \
  -p 127.0.0.1:${PORT_INTERNAL}:10001 \
  -p 127.0.0.1:${PORT_TORII}:50051 \
  -v ${NAME_VOLUME}:/opt/iroha \
  --env NAME_KEY=${NAME_KEY} \
  --env IP_IROHA_NODE=${IP_IROHA_NODE} \
  --name=${NAME} \
  divax/iroha:latest
