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
  && apt-get install -y \
    dnsmasq \
    pwgen \
    postgresql-10 \
  && mv /var/lib/postgresql/10/main/ /opt/iroha/data/postgres \
  && chmod +x /entrypoint.sh /wait-for-it.sh

# postgres, iroha torii
EXPOSE 5432 50051

VOLUME [ "/opt/iroha/" ]
WORKDIR "/opt/iroha/data/"
ENTRYPOINT ["/entrypoint.sh"]
