#!/usr/bin/env bash

set -e

APP_PATH=/var/lib/docker/volumes/${1}/_data/data/

if [ $# -eq 0 ] || ! [ -d $APP_PATH ] ; then
  echo "Usage: ./deploy.sh IROHA-CONTAINER-VOLUME"
  echo "  IROHA-CONTAINER-VOLUME must be an existing docker container holding iroha data"
  echo
  echo "Example"
  echo "  ./deploy.sh iroha0_iroha"
  exit 1;
fi

export PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $PROJECT_PATH

for pathcomponent in bin model src static view ; do
  rm -R ${APP_PATH}${pathcomponent} \
    && cp -R ${PROJECT_PATH}/app/${pathcomponent} ${APP_PATH}
done

chown -R 1000:1000 ${APP_PATH}
