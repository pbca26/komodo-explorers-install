#!/usr/bin/env bash
################################################################################
# Script for installing Insight Explorer on Ubuntu 18.04 and 20.04
# Authors: @rumeysayilmaz @aklix @pbca26
#-------------------------------------------------------------------------------
# This bash script was taken from Decker (@DeckerSU) and modified for single
# blockchain
#-------------------------------------------------------------------------------
# sudo chmod +x install-marmara-explorer.sh
# Execute the script to install Insight Explorer:
# ./install-marmara-explorer.sh
#-------------------------------------------------------------------------------
# In case of failure during running of this script, please remove *-explorer
# folders, *-explorer- start.sh files, and node_modules folder before you
# run ./install-marmara-explorer.sh again!.
# This will prevent any incomplete installation errors.
# Recommended Node version: v8.17.0
# To enable Tokens CC V2 API refer to https://github.com/pbca26/insight-api-komodo/tree/tokens#tokens-cc-v2
################################################################################

STEP_START='\e[1;47;42m'
STEP_END='\e[0m'

CUR_DIR=$(pwd)
COIN="TOKENSV2"
#KOMODO_DIR="Library/Application Support/Komodo"
KOMODO_DIR=".komodo"
echo Current directory: $CUR_DIR
echo Komodo directory: $KOMODO_DIR
echo Coin: $COIN

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
nvm use v8
# npm install bitcore
npm install git+https://git@github.com/pbca26/bitcore-node-komodo#tokens

echo -e "$STEP_START[ Step 3 ]$STEP_END Creating coin configs and deploy explorers"

# Start ports
file="$HOME/$KOMODO_DIR/$COIN/$COIN.conf"
rpcport=$(cat "$file"| grep rpcport | sed 's/rpcport=//g')
rpcuser=$(cat "$file"| grep rpcuser | sed 's/rpcuser=//g')
rpcpassword=$(cat "$file"| grep rpcpassword | sed 's/rpcpassword=//g')
zmqport=$(($rpcport+1))
webport=3001

# # Coin config
echo -e "$STEP_START[ Step 4 ]$STEP_END Preparing $COIN"

cat <<EOF > $HOME/$KOMODO_DIR/$COIN/$COIN.conf
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:$zmqport
zmqpubhashblock=tcp://127.0.0.1:$zmqport
rpcallowip=127.0.0.1
rpcport=$rpcport
rpcuser=$rpcuser
rpcpassword=$rpcpassword
uacomment=bitcore
showmetrics=0

EOF

# Create coin explorer and bitcore-node.json config for it

$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node create $COIN-explorer
cd $COIN-explorer
$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node install git+https://git@github.com/pbca26/insight-api-komodo#tokens git+https://git@github.com/pbca26/insight-ui-komodo#tokens
cd $CUR_DIR

cat << EOF > $CUR_DIR/$COIN-explorer/bitcore-node.json
{
  "network": "mainnet",
  "port": $webport,
  "services": [
    "bitcoind",
    "insight-api-komodo",
    "insight-ui-komodo",
    "web"
  ],
  "tokens": {
    "version": "v2"
  },
  "servicesConfig": {
    "bitcoind": {
      "connect": [
        {
          "rpchost": "127.0.0.1",
          "rpcport": $rpcport,
          "rpcuser": "$rpcuser",
          "rpcpassword": "$rpcpassword",
          "zmqpubrawtx": "tcp://127.0.0.1:$zmqport"
        }
      ]
    },
    "insight-api-komodo": {
      "rateLimiterOptions": {
        "whitelist": ["::ffff:127.0.0.1","127.0.0.1"],
        "whitelistLimit": 500000,
        "whitelistInterval": 3600000
      }
    }
  }
}

EOF

# creating launch script for coin explorer
cat << EOF > $CUR_DIR/$COIN-explorer-start.sh
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
cd $COIN-explorer
nvm use v8; ./node_modules/bitcore-node-komodo/bin/bitcore-node start
EOF
sudo chmod +x $COIN-explorer-start.sh
