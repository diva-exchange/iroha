# Hyperledger/Iroha Blockchain

The blockchain backend of _diva_ is based on Hyperledger/Iroha. 

_Important:_ these instructions are suitable for a testnet in a development environment (not production). This project contains well-known private keys (so they are not private anymore). To understand the cryptography related to Iroha, read the docs: https://iroha.readthedocs.io/en/master/  

## Get Started

DIVA.EXCHANGE offers preconfigured packages to start or join  an Iroha testnet: 
https://codeberg.org/diva.exchange/diva-dockerized

For a beginner it's probably easier to use the preconfigured package. The instructions below show how to sta

### Docker

Pull the image using docker:
`docker pull divax/iroha:latest`

Create a new bash/shell script (adapt the environment variables according to your needs):

```
#!/usr/bin/env bash

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

# @TODO replace environment variables with arguments, like: run.sh --id=2
ID_INSTANCE=${ID_INSTANCE:-${1:-1}}
IP_CONTAINER="172.19.${ID_INSTANCE}.10"
IP_IROHA_NODE="172.19.${ID_INSTANCE}.11"
SUBNET="172.19.${ID_INSTANCE}.0/24"
GATEWAY="172.19.${ID_INSTANCE}.1"

BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK:-tn-`date -u +%s`-${RANDOM}}
NAME_KEY=${NAME_KEY:-${BLOCKCHAIN_NETWORK}-${RANDOM}}
NAME=iroha-${ID_INSTANCE}

# create the network
NETWORK_NAME=iroha-net-${ID_INSTANCE}
[[ $(docker network inspect ${NETWORK_NAME} 2>/dev/null | wc -l) > 1 ]] || \
  docker network create \
    --driver=bridge \
    --subnet=${SUBNET} \
    --gateway=${GATEWAY} \
    ${NETWORK_NAME}

# start the container
docker run \
  -d \
  -p 127.19.${ID_INSTANCE}.1:5432:5432 \
  -p 127.19.${ID_INSTANCE}.1:10001:10001 \
  -p 127.19.${ID_INSTANCE}.1:50051:50051 \
  -v ${NAME}:/opt/iroha \
  --env BLOCKCHAIN_NETWORK=${BLOCKCHAIN_NETWORK} \
  --env NAME_KEY=${NAME_KEY} \
  --env IP_IROHA_NODE=${IP_IROHA_NODE} \
  --env IP_CONTAINER=${IP_CONTAINER} \
  --name=${NAME} \
  --network=${NETWORK_NAME} \
  --ip=${IP_CONTAINER} \
  --rm \
  divax/iroha:latest

echo "Running ${NAME_KEY} on blockchain network ${BLOCKCHAIN_NETWORK}"

```

Execute the above shell script in your environment.

A new network and a new container will be created. Explore it using the docker tools, like `docker ps -a` or `docker inspect some-name`. To stop and remove the container and/or network, use the docker tools.

### Source Code

Clone the code from git:

```
cd /home/me/my-stuff/
git clone -b master https://codeberg.org/diva.exchange/iroha.git
cd iroha
```

Now you can either start an Iroha container using the existing configuration (with the given keys) - or you can configure your own.

#### Start the Preconfigured Container 

Make sure you are located in the `iroha` folder. To access Docker you need root rights. This will start a container:

```
sudo ./bin/start.sh
```
 
 Now you have an Iroha Container up and running. Important: this uses preconfigured, well-known (publicly available) private keys. Use it for testing/development only.

#### Stop the Preconfigured Container 

```
sudo ./bin/halt.sh
```
 
#### Build your Own  

Within the folder `data-genesis` you can configure your own Genesis Block. Execute `./bin/genesis.sh` to create your own Genesis Block. Take a close look at the script to understand how the private keys are handled!

Then, based on your own Genesis Block, build your own Docker Image: `./bin/build.sh`.

After building, run your container using `./bin/run.sh`. 

## Contact the Developers

On [DIVA.EXCHANGE](https://www.diva.exchange) you'll find various options to get in touch with the team. 

Talk to us via Telegram [https://t.me/diva_exchange_chat_de]() (English or German).

## Donations

Your donation goes entirely to the project. Your donation makes the development of DIVA.EXCHANGE faster.

XMR: 42QLvHvkc9bahHadQfEzuJJx4ZHnGhQzBXa8C9H3c472diEvVRzevwpN7VAUpCPePCiDhehH4BAWh8kYicoSxpusMmhfwgx

BTC: 3Ebuzhsbs6DrUQuwvMu722LhD8cNfhG1gs

Awesome, thank you!
