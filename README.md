## Marmara Insight Explorer

Marmara explorer is based on the **master** branch of [https://github.com/marmarachain/marmara/tree/master](https://github.com/marmarachain/marmara/tree/master). 

**Prerequisites and Conditions**
- This guide assumes that Marmara *has already been downloaded* to the machine.
- Tested on Ubuntu 18.04.5 and Ubuntu 20.04

> For detailed list of dependencies, check out the [package.json](https://github.com/marmarachain/bitcore-node-komodo/blob/master/package.json) file.

### How to Install?
Clone the git repo to local machine into a directory named explorer and inside the directory run the bash script to create the Marmara explorer and the relevant bitcore modules: 

```sh
git clone https://github.com/marmarachain/marmara-explorer-install.git explorer
cd explorer
sudo chmod +x install-marmara-explorer.sh
./install-marmara-explorer.sh
```
> Important Notice: In case of failure, remove *-explorer folders, *-explorer-start.sh files and node modules folder before running ./install-marmara-explorer.sh script again.

Running the command above creates a directory structure under ```explorer``` directory as shown below:

```
explorer
│   README.md
│   install-marmara-explorer.sh
│   marmara-explorer-start.sh
│
│───node_modules
│   │
│   └───bitcore-node-komodo
│       │   ...
│
│───marmara-explorer
│    │   bitcore-node.json
│    │   package.json
│    │
│    └──node_modules
│       │
│	│───bitcore-lib-komodo
│	│   │   ...
│    	│
│	│───bitcore-node-komodo
│	│   │   ...
│    	│
│	│───insight-api-komodo
│	│   │   ...
│    	│
│	│───insight-ui-komodo
│	│   │   ...
```

Having completed these steps, start the daemon with the starting parameters in another terminal: 

```sh
./komodod -ac_name=MCL -ac_supply=2000000 -ac_cc=2 -addnode=37.148.210.158 -addnode=37.148.212.36 -addressindex=1 -spentindex=1 -ac_marmara=1 -ac_staked=75 -ac_reward=3000000000 &
```
Then, in the command line interface, run the bash script as follows:
```sh
./marmara-explorer-start.sh
```
#### Make explorer and MCL run as a service

```sh
sudo chmod +x marmarad_service.sh
./marmard_service.sh
cd
sudo mv marmarad.service explorer-marmara.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable marmarad.service explorer-marmara.service
sudo service marmara-explorer start
```

Important notes for running explorer given by @DeckerSU are stated below:
- Having run ``./install-marmara-explorer.sh``, make sure you have all needed indexes enabled in MCL.conf:
```
txindex=1
addressindex=1
timestampindex=1
spentindex=1
```

- Make sure the chain is synced with these indexes enabled. Look into debug.log, at daemon startup you should see:
```
LoadBlockIndexDB: transaction index enabled 
LoadBlockIndexDB: address index enabled
LoadBlockIndexDB: timestamp index enabled
LoadBlockIndexDB: spent index enabled
```
> Even if one of them is disabled - it's incorrect.

- Make sure that getblockhashes RPC is working. If it's not working, re-check everything.
- If one is not sure of the mistake being made, delete everything except MCL.conf and sync chain from scratch.

## Multilanguage Support for Insight-ui-Marmara

The README file in [here](https://github.com/marmarachain/insight-ui-marmara) explains the multilanguage support for the explorer. The steps are given briefly below:

Under the directory ``explorer/marmara-explorer/node_modules/insight-ui-komodo`` run the following command to install the project dependencies listed in bower.json:

```
$ bower install

```
To generate a template.pot file in po/ folder, issue the following command in ``explorer/marmara-explorer/node_modules/insight-ui-komodo``:
```
$ ./node_modules/.bin/grunt nggettext_extract 

```
Having generated the template.pot file, use a PO editor such as Poedit software and follow this [guide](https://angular-gettext.rocketeer.be/dev-guide/translate/) to learn how to edit/update/import PO files from a generated POT file. Select the respective language. Having completed the translations, a PO file will be generated inside po/ folder. 

Add the language inside the js file, ``insight-ui-komodo/public/src/js/controllers/footer.js``, under ```$scope.availableLanguages```.

To compile and minify the web application's assets, run the following command (This command is also necessary to generate the angular javascript ``js/translations.js``.) :

```
$ grunt compile

```
> Every time a change is made in the html tags, simply run grunt compile again to generate a new .pot template and the angular javascript ``js/translations.js``. Then (if use Poedit), open .po file and choose update from POT File from Catalog menu.

## Acknowledgements
The installation script of @DeckerSU in [here](https://github.com/DeckerSU/komodo-explorers-install) was modified to work for single chain i.e. Marmarachain.  
Special thanks to @DeckerSu for their hardwork and special thanks to @pbca26 for their valuable contributions, assistance and guide while getting the explorer work.

Improvements are welcomed through PR.
