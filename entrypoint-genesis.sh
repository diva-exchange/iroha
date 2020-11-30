#!/usr/bin/env bash
#
# Copyright (C) 2020 diva.exchange
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author/Maintainer: Konrad Bächler <konrad@diva.exchange>
#

# -e  Exit immediately if a simple command exits with a non-zero status
set -e

/wait-for-it.sh postgres_genesis:5432 -t 30

# re-creating all testnet keys
iroha-cli -new_account -account_name diva@testnet
iroha-cli -new_account -account_name tn1
iroha-cli -new_account -account_name tn2
iroha-cli -new_account -account_name tn3
iroha-cli -new_account -account_name genesis-node

DIVA_TESTNET=$(<diva@testnet.pub)
TN1=$(<tn1.pub)
TN2=$(<tn2.pub)
TN3=$(<tn3.pub)

# replace the key values in the genesis.block setup
sed -i 's!\$DIVA_TESTNET!'"${DIVA_TESTNET}"'!g ; s!\$TN1!'"${TN1}"'!g ; s!\$TN2!'"${TN2}"'!g ; s!\$TN3!'"${TN3}"'!g' genesis.block

# create the genesis block
irohad \
  --overwrite_ledger \
  --genesis_block genesis.block \
  --config config-genesis.json \
  --keypair_name genesis-node
