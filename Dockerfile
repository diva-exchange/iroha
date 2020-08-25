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

FROM hyperledger/iroha:1.1.3

LABEL author="Konrad Baechler <konrad@diva.exchange>" \
  maintainer="Konrad Baechler <konrad@diva.exchange>" \
  name="diva-iroha" \
  description="Distributed digital value exchange upholding security, reliability and privacy" \
  url="https://diva.exchange"

COPY data/* /opt/iroha/data/
COPY blockstore/* /opt/iroha/blockstore/
COPY network/* /
COPY database/* /
COPY entrypoint.sh wait-for-it.sh /

RUN apt-get update \
  && apt-get -y install \
    curl \
    dnsmasq \
    pwgen \
    postgresql-10 \
  && mv /var/lib/postgresql/10/main/ /opt/iroha/data/postgres \
  && chmod +x /entrypoint.sh /wait-for-it.sh

# postgres, iroha internal and iroha torii
EXPOSE 5432 10001 50051

VOLUME [ "/opt/iroha/" ]
WORKDIR "/opt/iroha/data/"
ENTRYPOINT ["/entrypoint.sh"]
