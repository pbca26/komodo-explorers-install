#!/usr/bin/env bash
################################################################################
# Script for installing MARMARA Explorer on Ubuntu 18.04 and 20.04
# Authors: @rumeysayilmaz @aklix
#-------------------------------------------------------------------------------
# This bash script was taken from Decker (@DeckerSU) and modified for single
# blockchain i.e. Marmara.
#-------------------------------------------------------------------------------
# sudo chmod +x install-marmara-explorer.sh
# Execute the script to install Marmara Explorer:
# ./install-marmara-explorer.sh
#-------------------------------------------------------------------------------
# In case of failure during running of this script, please remove *-explorer
# folders, *-explorer- start.sh files, and node_modules folder before you
# run ./install-marmara-explorer.sh again!.
# This will prevent any incomplete installation errors.
################################################################################

STEP_START='\e[1;47;42m'
STEP_END='\e[0m'

CUR_DIR=$(pwd)
echo Current directory: $CUR_DIR
echo -e "$STEP_START[ Step 1 ]$STEP_END Installing dependencies"
sudo apt --yes install git
sudo apt --yes install build-essential pkg-config libc6-dev m4 g++-multilib autoconf libtool ncurses-dev unzip git python python-zmq zlib1g-dev wget libcurl4-gnutls-dev bsdmainutils automake curl libsodium-dev
sudo apt --yes install libcurl4-gnutls-dev
sudo apt --yes install curl wget


echo -e "$STEP_START[ Step 2 ]$STEP_END Installing NodeJS and Bitcore Node"

sudo apt --yes install libsodium-dev
sudo apt --yes install libzmq3-dev

# install nvm
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.35.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

# switch node setup with nvm
nvm install v4
# npm install bitcore
npm install git+https://git@github.com/marmarachain/bitcore-node-komodo

echo -e "$STEP_START[ Step 3 ]$STEP_END Creating MCL configs and deploy explorers"

# Start ports
file="$HOME/.komodo/MCL/MCL.conf"
rpcport=$(cat "$file"| grep rpcport | sed 's/rpcport=//g')
rpcuser=$(cat "$file"| grep rpcuser | sed 's/rpcuser=//g')
rpcpassword=$(cat "$file"| grep rpcpassword | sed 's/rpcpassword=//g')
zmqport=$(($rpcport+1))
webport=3001

# MCL config
echo -e "$STEP_START[ Step 4 ]$STEP_END Preparing MCL"

cat <<EOF > $HOME/.komodo/MCL/MCL.conf
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

# Create marmara explorer and bitcore-node.json config for it

$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node create marmara-explorer
cd marmara-explorer
$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node install git+https://git@github.com/marmarachain/insight-api-marmara git+https://git@github.com/marmarachain/insight-ui-marmara
cd $CUR_DIR

cat << EOF > $CUR_DIR/marmara-explorer/bitcore-node.json
{
  "network": "mainnet",
  "port": $webport,
  "services": [
    "bitcoind",
    "insight-api-komodo",
    "insight-ui-komodo",
    "web"
  ],
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

# creating launch script for Marmara explorer
cat << EOF > $CUR_DIR/marmara-explorer-start.sh
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
cd marmara-explorer
nvm use v4; ./node_modules/bitcore-node-komodo/bin/bitcore-node start
EOF
sudo chmod +x marmara-explorer-start.sh


