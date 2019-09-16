#!/usr/bin/env bash

set -e

if [ $# -eq 0 ] || ! [[ $1 =~ ^-?[0-9]+$ ]] || [ $1 -lt 1 ] || [ $1 -gt 10 ] ; then
  echo "Usage: ./up.sh INSTANCES"
  echo "  INSTANCES must be between 1 and 10"
  echo
  echo "Example"
  echo "  ./up.sh 4"
  echo "  Starts four independent instances using"
  echo "    docker-compose up"
  echo "  with the corresponding environment."
  exit 1;
fi

export PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $PROJECT_PATH

PATH_INPUT_YML=template.docker-compose.yml
for ((IDENT_INSTANCE = 0 ; IDENT_INSTANCE <= $(($1 - 1)) ; IDENT_INSTANCE++)); do
  set -a
  source iroha-diva.env
  PATH_OUTPUT_YML=/tmp/docker-compose-up-$IDENT_INSTANCE.yml
  envsubst < $PATH_INPUT_YML > $PATH_OUTPUT_YML
  set +a

  export IDENT_INSTANCE
  echo "Starting instance $IDENT_INSTANCE"
  docker-compose -f $PATH_OUTPUT_YML up -d
  rm $PATH_OUTPUT_YML
done
