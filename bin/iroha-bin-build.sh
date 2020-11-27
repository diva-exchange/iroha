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

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/../
cd ${PROJECT_PATH}

TAG=${TAG:-1.2.0}
docker build -f Dockerfile-Build --force-rm -t divax/iroha-build:${TAG} .
docker run -v iroha-build:/root/ --name iroha-build divax/iroha-build:${TAG}

# copy binaries
docker cp iroha-build:/root/iroha-cli ./build/iroha-cli-${TAG}-org
docker cp iroha-build:/root/irohad ./build/irohad-${TAG}-org
docker cp iroha-build:/root/iroha-cli-stripped ./build/iroha-cli-${TAG}
docker cp iroha-build:/root/irohad-stripped ./build/irohad-${TAG}
chown --reference build build/*
docker rm iroha-build

${PROJECT_PATH}bin/build.sh
