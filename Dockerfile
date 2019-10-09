FROM hyperledger/iroha:1.1.0

LABEL author="Konrad Baechler <konrad@diva.exchange>" \
  maintainer="Konrad Baechler <konrad@diva.exchange>" \
  name="diva.iroha" \
  description="Distributed digital value exchange upholding security, reliability and privacy" \
  url="https://diva.exchange"

COPY data/* /opt/iroha/data/
COPY blockstore/* /opt/iroha/blockstore/
COPY network/* /
COPY entrypoint.sh wait-for-it.sh /

RUN apt-get update \
  && apt-get install -y \
    dnsmasq \
    nano \
    iputils-ping \
  && chmod +x /entrypoint.sh /wait-for-it.sh

VOLUME [ "/opt/iroha/" ]
WORKDIR "/opt/iroha/data/"
ENTRYPOINT ["/entrypoint.sh"]
