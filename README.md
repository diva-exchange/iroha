# Hyperledger/Iroha Blockchain

The blockchain backend of _diva_ is based on Hyperledger/Iroha. 

_Important:_ these instructions are suitable for a testnet in a development environment (not production). This project contains well-known private keys (so they are not private anymore). To understand the cryptography related to Iroha, read the docs: https://iroha.readthedocs.io/en/master/  

## Get Started

DIVA.EXCHANGE offers preconfigured packages to start or join the DIVA.EXCHANGE Iroha testnet.

For beginners it's probably easier to use the preconfigured package "diva-dockerized" (https://codeberg.org/diva.exchange/diva-dockerized).

For a bit more experienced users on an operating systems supporting Docker (Linux, Windows, MacOS) the following instructions will help to get started.

### Using Docker Compose

Clone the code repository from our public repository:
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

### Source Code and Building using Docker

Clone the code from git:

```
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

After building, run your container using `./bin/start.sh`. 

## Contact the Developers

On [DIVA.EXCHANGE](https://www.diva.exchange) you'll find various options to get in touch with the team. 

Talk to us via Telegram [https://t.me/diva_exchange_chat_de]() (English or German).

## Donations

Your donation goes entirely to the project. Your donation makes the development of DIVA.EXCHANGE faster.

XMR: 42QLvHvkc9bahHadQfEzuJJx4ZHnGhQzBXa8C9H3c472diEvVRzevwpN7VAUpCPePCiDhehH4BAWh8kYicoSxpusMmhfwgx

BTC: 3Ebuzhsbs6DrUQuwvMu722LhD8cNfhG1gs

Awesome, thank you!
