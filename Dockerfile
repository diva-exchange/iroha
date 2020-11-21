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

FROM debian:bullseye-slim

LABEL author="Konrad Baechler <konrad@diva.exchange>" \
  maintainer="Konrad Baechler <konrad@diva.exchange>" \
  name="diva-iroha" \
  description="Distributed digital value exchange upholding security, reliability and privacy" \
  url="https://diva.exchange"

ARG TAG=1.2.0-rc2

COPY build/iroha-cli-$TAG /usr/bin/iroha-cli
COPY build/irohad-$TAG /usr/bin/irohad
COPY data /opt/iroha/data/
COPY network/* /
COPY entrypoint.sh wait-for-it.sh /

RUN mkdir -p /opt/iroha/blockstore/ \
  && apt-get update \
  && apt-get -y install \
    dnsmasq \
    pwgen \
    iproute2 \
    procps \
    zip \
  && chmod +x /entrypoint.sh /wait-for-it.sh

# iroha internal and iroha torii
EXPOSE 10001 50051

VOLUME [ "/opt/iroha/" ]
WORKDIR "/opt/iroha/data/"
ENTRYPOINT ["/entrypoint.sh"]
