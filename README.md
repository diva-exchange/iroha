# Hyperledger/Iroha Blockchain

The blockchain backend of _diva_ is based on Hyperledger/Iroha. 

_Important:_ these instructions are suitable for a testnet in a development environment (not production). This project contains well-known private keys (so they are not private anymore). To understand the cryptography related to Iroha, read the docs: https://iroha.readthedocs.io/en/master/  

## Get Started

### Docker

Pull the image using docker:
`docker pull divax/iroha:latest`

Now execute in a Linux shell (accessing docker needs root rights):
```
IP_IROHA_NODE=${IP_IROHA_NODE:-"0.0.0.0"}
PORT_POSTGRES=${PORT_POSTGRES:-5032}
PORT_INTERNAL=${PORT_INTERNAL:-10001}
PORT_TORII=${PORT_TORII:-50051}

NAME_KEY=${NAME_KEY:-testnet-a}
NAME=${NAME:-iroha-${NAME_KEY}}
NAME_VOLUME=${NAME_VOLUME:-${NAME}}

# start the container
docker run \
  -d \
  -p 127.0.0.1:${PORT_POSTGRES}:5432 \
  -p 127.0.0.1:${PORT_INTERNAL}:10001 \
  -p 127.0.0.1:${PORT_TORII}:50051 \
  -v ${NAME_VOLUME}:/opt/iroha \
  --env NAME_KEY=${NAME_KEY} \
  --env IP_IROHA_NODE=${IP_IROHA_NODE} \
  --name=${NAME} \
  divax/iroha:latest
```

On other operating systems: adapt the environment variables according to your needs. 

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

`sudo ./bin/run.sh`
 
 Now you have an Iroha Container up and running. Important: this uses preconfigured, well-known (publicly available) private keys. Use it for testing/development only.
 
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
