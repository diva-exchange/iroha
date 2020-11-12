# DIVA.EXCHANGE: Hyperledger/Iroha Blockchain

This is an open source project (AGPLv3 licensed) - transparently developed by the association [DIVA.EXCHANGE](https://diva.exchange).

All source code is available here: https://codeberg.org/diva.exchange/iroha/.

The blockchain backend of _diva_ is based on Hyperledger/Iroha. 

_Important:_ these instructions are suitable for a testnet in a development environment (not production). This project contains well-known private keys (so they are not private anymore). To understand the cryptography related to Iroha, read the docs: https://iroha.readthedocs.io/en/master/  

## Get Started

DIVA.EXCHANGE offers preconfigured packages to start or join the DIVA.EXCHANGE Iroha testnet.

It's probably best to use the preconfigured package "diva-dockerized" (https://codeberg.org/diva.exchange/diva-dockerized).

For advanced users on an operating system supporting Docker (Linux, Windows, MacOS) the following instructions will help to get started.

### Using Docker Compose

Clone the code repository from the public repository:
```
git clone -b master https://codeberg.org/diva.exchange/iroha.git
cd iroha
```

To start a preconfigured local Iroha make sure you have "Docker Compose" installed (https://docs.docker.com/compose/install/). Check your Docker Compose installation by executing `docker-compose --version` in a terminal.

If you have Docker Compose available, just execute within your iroha folder:
```
sudo docker-compose up -d
```

After a short while you will find four docker container running: a postgres and three iroha container (testnet-a, testnet-b and testnet-c).

To stop the container using Docker Compose, execute:
```
sudo docker-compose down
```
 
To stop the container, including the removal of the related volumes (data of the containers gets removed, so the local blockchain gets deleted) using Docker Compose, execute:
```
sudo docker-compose down --volumes
```
 
## Build your Own Genesis Block

Make sure, the code is available by cloning the code repository from the public repository:
```
git clone -b master https://codeberg.org/diva.exchange/iroha.git
cd iroha
```

Within the folder `data-genesis` you can configure your own Genesis Block. Execute
```
sudo ./bin/genesis.sh
```
to create your own Genesis Block. Take a close look at the script to understand how the private keys are handled!

After building the Genesis Block, run your container using Docker Compose 
```
sudo docker-compose up -d
```

## Environment variables

Within the compose file (docker-compose.yml) some environment variables are used. They might be adapted to local needs.

### LOG_LEVEL
Set the iroha log level: trace, debug, info, warning, error, critical. Defaults to info.

### TYPE
Either NONE or I2P. NONE does not use any proxy. I2P looks for an I2P proxy and tries to use it. Defaults to NONE.

### BLOCKCHAIN_NETWORK
Name of the iroha blockchain network to run. Defaults to an empty string and gets therefore set automatically by the entrypoint script.

### NAME_KEY
Name of the iroha node and the private/public key. Defaults to an empty string and gets therefore set automatically by the entrypoint script. 

### IP_IROHA_API
IP address of the related Iroha API container. Use the string "bridge" to use the docker gateway IP. 
 
### PORT_IROHA_API
Proxy port of the Iroha API container. Defaults to 19012.

### IP_HTTP_PROXY
IP address of the container running an HTTP proxy. 

### PORT_HTTP_PROXY
Port of the container running an HTTP proxy. 

## Contact the Developers

On [DIVA.EXCHANGE](https://www.diva.exchange) you'll find various options to get in touch with the team. 

Talk to us via [Telegram](https://t.me/diva_exchange_chat_de) (English or German).

## Donations

Your donation goes entirely to the project. Your donation makes the development of DIVA.EXCHANGE faster.

XMR: 42QLvHvkc9bahHadQfEzuJJx4ZHnGhQzBXa8C9H3c472diEvVRzevwpN7VAUpCPePCiDhehH4BAWh8kYicoSxpusMmhfwgx

BTC: 3Ebuzhsbs6DrUQuwvMu722LhD8cNfhG1gs

Awesome, thank you!
