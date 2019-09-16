#!/usr/bin/env bash
#
# Author/Maintainer: konrad@getdiva.org
#
set -e

/wait-for-it.sh postgres_genesis:5432 -t 30 -s -- \
  irohad \
    --overwrite_ledger \
    --genesis_block genesis.block \
    --config config-genesis.json \
    --keypair_name node_genesis
