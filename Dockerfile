FROM hyperledger/iroha:1.1.3

LABEL author="Konrad Baechler <konrad@diva.exchange>" \
  maintainer="Konrad Baechler <konrad@diva.exchange>" \
  name="diva.iroha" \
  description="Distributed digital value exchange upholding security, reliability and privacy" \
  url="https://diva.exchange"

COPY app /opt/iroha/app
COPY package.* /opt/iroha/
COPY data/* /opt/iroha/data/
COPY blockstore/* /opt/iroha/blockstore0/
COPY blockstore/* /opt/iroha/blockstore1/
COPY blockstore/* /opt/iroha/blockstore2/
COPY network/* /
COPY database/* /
COPY entrypoint.sh wait-for-it.sh /

RUN apt-get update \
  && apt-get install -y \
    dnsmasq \
    nano \
    curl \
    dirmngr \
    apt-transport-https \
    lsb-release \
    ca-certificates \
    postgresql-10 \
  && mv /var/lib/postgresql/10/main/ /opt/iroha/data/postgres \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y \
    nodejs \
  && chmod +x /entrypoint.sh /wait-for-it.sh \
  && cd /opt/iroha/ \
  && npm install --production \
  && useradd --system node \
  && chown -R node:node /opt/iroha/app


# torii and postgres
EXPOSE 50051 5432

VOLUME [ "/opt/iroha/" ]
WORKDIR "/opt/iroha/data/"
ENTRYPOINT ["/entrypoint.sh"]
