#!/usr/bin/env bash

set -e

export PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $PROJECT_PATH

IDENT_INSTANCE=0
PATH_INPUT_YML=template.docker-compose.yml
PATH_OUTPUT_YML=/tmp/docker-compose-$IDENT_INSTANCE.yml

set -a
source iroha-diva.env
envsubst < $PATH_INPUT_YML > $PATH_OUTPUT_YML
set +a

export IDENT_INSTANCE
docker-compose -f $PATH_OUTPUT_YML build --no-cache --force-rm iroha0
rm $PATH_OUTPUT_YML
