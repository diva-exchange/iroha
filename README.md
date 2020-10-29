# Hyperledger/Iroha Blockchain

The blockchain backend of _diva_ is based on Hyperledger/Iroha. 

_Important:_ these instructions are suitable for a testnet in a development environment (not production). This project contains well-known private keys (so they are not private anymore). To understand the cryptography related to Iroha, read the docs: https://iroha.readthedocs.io/en/master/  

## Get Started

DIVA.EXCHANGE offers preconfigured packages to start or join the DIVA.EXCHANGE Iroha testnet.

It's probably best to use the preconfigured package "diva-dockerized" (https://codeberg.org/diva.exchange/diva-dockerized).

For experienced users on an operating systems supporting Docker (Linux, Windows, MacOS) the following instructions will help to get started.

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

After a short while you will find two docker container running: a postgres and an iroha container.

To stop the containers using Docker Compose, execute:
```
sudo docker-compose down
```
 
To stop the containers, including the removal of the related volumes (data of the containers gets removed, so the local blockchain gets deleted) using Docker Compose, execute:
```
sudo docker-compose down --volumes
```
 
#### Build your Own Genesis Block

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

After building the Genesis Block, *build* and run your container using Docker Compose 
```
sudo docker-compose up -d --build
```

## Environment variables

Within the compose file (docker-compose.yml) some environment variables are used. They might be adapted to local needs.

### TYPE
Either NONE, I2P or P2P. NONE does not use any proxy. I2P looks for an I2P proxy and tries to use it. P2P looks for an peer-to-peer proxy and tries to use it. I2P is recommended, P2P is unstable and experimental. Defaults to NONE.

### IP_PUBLISHED 
Published IP address of the iroha container. Mandatory. Reasonable value: 127.19.10.3.

### BLOCKCHAIN_NETWORK
Name of the iroha blockchain network to run. Defaults to an empty string and gets therefore set automatically by the entrypoint script.

### NAME_KEY
Name of the iroha node and the private/public key. Defaults to an empty string and gets therefore set automatically by the entrypoint script. 

### IP_IROHA_PROXY
IP address of the related iroha proxy container (used in P2P networks). Use the string "bridge" to use the docker gateway IP. "bridge" is the reasonable setting in a P2P environment. Defaults to an empty string and therefore no proxy gets used.   
 
### PORT_IROHA_PROXY
Proxy port of the P2P iroha proxy container. Defaults to 19011.

### PORT_CONTROL
Control port of the P2P iroha proxy container. Defaults to 19012.
  
## Contact the Developers

On [DIVA.EXCHANGE](https://www.diva.exchange) you'll find various options to get in touch with the team. 

Talk to us via Telegram [https://t.me/diva_exchange_chat_de]() (English or German).

## Donations

Your donation goes entirely to the project. Your donation makes the development of DIVA.EXCHANGE faster.

XMR: 42QLvHvkc9bahHadQfEzuJJx4ZHnGhQzBXa8C9H3c472diEvVRzevwpN7VAUpCPePCiDhehH4BAWh8kYicoSxpusMmhfwgx

BTC: 3Ebuzhsbs6DrUQuwvMu722LhD8cNfhG1gs

Awesome, thank you!
