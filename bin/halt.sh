#!/usr/bin/env bash
#
# Copyright (C) 2020 diva.exchange
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author/Maintainer: Konrad Bächler <konrad@diva.exchange>
#

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/../
cd ${PROJECT_PATH}

# @TODO replace environment variables with arguments, like: run.sh --id=2
ID_INSTANCE=${ID_INSTANCE:-${1:-1}}
NAME=iroha${ID_INSTANCE}

# stop Iroha
echo "Removing iroha..."
docker stop ${NAME}
docker rm ${NAME}

# stop Postgres
echo "Removing postgres..."
docker stop iroha-postgres
docker rm iroha-postgres

# remove unused volumes
echo "Pruning volumes..."
docker volume prune -f
