#!/usr/bin/env bash
#
# Author/Maintainer: konrad@diva.exchange
#
set -e

/wait-for-it.sh postgres_genesis:5432 -t 30 -s --

# re-creating all testnet keys
iroha-cli -new_account -account_name diva@testnet
iroha-cli -new_account -account_name testnet-a
iroha-cli -new_account -account_name testnet-b
iroha-cli -new_account -account_name testnet-c

DIVA_TESTNET=$(<diva@testnet.pub)
TESTNET_A=$(<testnet-a.pub)
TESTNET_B=$(<testnet-b.pub)
TESTNET_C=$(<testnet-c.pub)

# replace the key values in the genesis.block setup
sed -i 's!\$DIVA_TESTNET!'"${DIVA_TESTNET}"'!g ; s!\$TESTNET_A!'"${TESTNET_A}"'!g ; s!\$TESTNET_B!'"${TESTNET_B}"'!g ; s!\$TESTNET_C!'"${TESTNET_C}"'!g' genesis.block

# create the genesis block
irohad \
  --overwrite_ledger \
  --genesis_block genesis.block \
  --config config-genesis.json \
  --keypair_name node_genesis
