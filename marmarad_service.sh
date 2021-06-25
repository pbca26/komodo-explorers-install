#!/bin/bash
CUR_DIR=$(pwd)
cat <<EOF >$HOME/marmarad.service
[Unit]
Description=komodo daemon for MCL chain

[Service]
WorkingDirectory=$HOME/komodo/src/
ExecStart=$HOME/komodo/src/komodod -ac_name=MCL -ac_supply=2000000 -ac_cc=2 -addnode=37.148.210.158 -addnode=37.148.212.36 -addnode=149.202.158.145 -txindex=1 -addressindex=1 -spentindex=1 -timestampindex=1 -ac_marmara=1 -ac_staked=75 -ac_reward=3000000000
ExecStop=$HOME/komodo/src/komodo-cli -ac_name=MCL stop
User=$USER

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >$HOME/explorer-marmara.service
[Unit]
Description=marmara explorer service
Requires=marmarad.service
After=marmarad.service

[Service]
WorkingDirectory= $CUR_DIR/
ExecStart=$CUR_DIR/marmara-explorer-start.sh
User=$USER

[Install]
WantedBy=multi-user.target
EOF
