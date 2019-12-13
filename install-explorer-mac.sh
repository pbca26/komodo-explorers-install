#!/bin/bash

#
# (c) Decker, 2018
#

# Additional info:
#
# If previous installation of all explorers failure in some reasons, plz remove *-explorer folders, *-explorer-start.sh files,
# and node_modules folder before you run ./install-explorer.sh again (!). It will prevent from uncomplete installation errors.
#

# https://askubuntu.com/questions/558280/changing-colour-of-text-and-background-of-terminal
STEP_START='\e[1;47;42m'
STEP_END='\e[0m'

CUR_DIR=$(pwd)
echo Current directory: $CUR_DIR
echo -e "$STEP_START[ Step 4 ]$STEP_END Creating komodod configs and deploy explorers"


# Start ports
rpcport=8232
zmqport=8332
webport=3001

# KMD config
echo -e "$STEP_START[ Step 4.KMD ]$STEP_END Preparing KMD"
mkdir -p $HOME/Library/Application\ Support/.Komodo
cat <<EOF > $HOME/Library/Application\ Support/.Komodo/komodo.conf
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
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=0
#connect=172.17.112.30

addnode=5.9.102.210
addnode=78.47.196.146
addnode=178.63.69.164
addnode=88.198.65.74
addnode=5.9.122.241
addnode=144.76.94.38
addnode=89.248.166.91
EOF

# Create KMD explorer and bitcore-node.json config for it

$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node create KMD-explorer
cd KMD-explorer
$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node install git+https://git@github.com/DeckerSU/insight-api-komodo git+https://git@github.com/DeckerSU/insight-ui-komodo
cd $CUR_DIR

cat << EOF > $CUR_DIR/KMD-explorer/bitcore-node.json
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
          "rpcuser": "bitcoin",
          "rpcpassword": "local321",
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

# creating launch script for explorer
cat << EOF > $CUR_DIR/KMD-explorer-start.sh
#!/bin/bash
cd KMD-explorer
./node_modules/bitcore-node-komodo/bin/bitcore-node start
EOF
chmod +x KMD-explorer-start.sh

# now we need to create assets configs for komodod and create explorers for each asset
#declare -a kmd_coins=(REVS SUPERNET DEX PANGEA JUMBLR BET CRYPTO HODL MSHARK BOTS MGW COQUI WLC KV CEAL MESH MNZ AXO ETOMIC BTCH PIZZA BEER NINJA OOT BNTN CHAIN PRLPAY DSEC GLXT EQL RICK MORTY)
source $CUR_DIR/kmd_coins.sh
#declare -a kmd_coins=(REVS)

for i in "${kmd_coins[@]}"
do
   echo -e "$STEP_START[ Step 4.$i ]$STEP_END Preparing $i"
   rpcport=$((rpcport+1))
   zmqport=$((zmqport+1))
   webport=$((webport+1))
   #printf "%10s: rpc.$rpcport zmq.$zmqport web.$webport\n" $i
   mkdir -p $HOME/Library/Application\ Support/.Komodo/$i
   touch $HOME/Library/Application\ Support/.Komodo/$i/$i.conf
cat <<EOF > $HOME/Library/Application\ Support/.Komodo/$i/$i.conf
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
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=0
#connect=172.17.112.30

addnode=5.9.102.210
addnode=78.47.196.146
addnode=178.63.69.164
addnode=88.198.65.74
addnode=5.9.122.241
addnode=144.76.94.38
addnode=89.248.166.91
EOF

$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node create $i-explorer
cd $i-explorer
$CUR_DIR/node_modules/bitcore-node-komodo/bin/bitcore-node install git+https://git@github.com/DeckerSU/insight-api-komodo git+https://git@github.com/DeckerSU/insight-ui-komodo
cd $CUR_DIR

cat << EOF > $CUR_DIR/$i-explorer/bitcore-node.json
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
          "rpcuser": "bitcoin",
          "rpcpassword": "local321",
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

# creating launch script for explorer
cat << EOF > $CUR_DIR/$i-explorer-start.sh
#!/bin/bash
cd $i-explorer
./node_modules/bitcore-node-komodo/bin/bitcore-node start
EOF
chmod +x $i-explorer-start.sh

done

echo -e "$STEP_START[ Step 5 ]$STEP_END Launching daemons"
#cd $CUR_DIR/komodo/src
#./assetchains
#cd $CUR_DIR

echo -e "$STEP_START[ Step 6 ]$STEP_END Applying nota api patch"
cd $CUR_DIR
cp ./nota-patch/bitcore-node-komodo/lib/services/bitcoind.js KMD-explorer/node_modules/bitcore-node-komodo/lib/services/bitcoind.js
cp ./nota-patch/insight-api-komodo/lib/status.js KMD-explorer/node_modules/insight-api-komodo/lib/status.js

for i in "${kmd_coins[@]}"
do
   cp ./nota-patch/bitcore-node-komodo/lib/services/bitcoind.js $i-explorer/node_modules/bitcore-node-komodo/lib/services/bitcoind.js
   cp ./nota-patch/insight-api-komodo/lib/status.js $i-explorer/node_modules/insight-api-komodo/lib/status.js
done