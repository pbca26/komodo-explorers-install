'use strict';

var fs = require('fs');

var Common = require('./common');

var TIP_SYNC_INTERVAL = 10;
var valueEnum = ['TotalNormals', 'TotalActivated', 'TotalLockedInLoops'];
var chartRangeEnum = [{
  name: '7d',
  title: '7 days',
  number: 7,
}, {
  name: '30d',
  title: '30 days',
  number: 30,
}, {
  name: '90d',
  title: '90 days',
  number: 90,
}, {
  name: 'all',
  title: 'all',
  number: 777,
}];

function StatsController(node) {
  this.node = node;
  this.statsPathRaw = this.node.configPath.replace('bitcore-node.json', 'marmara-stats-raw.json');
  this.statsPathComputed = this.node.configPath.replace('bitcore-node.json', 'marmara-stats-computed.json');
  this.common = new Common({log: this.node.log});
  this.cache = {
    raw: {
      marmaraAmountStatByBlocks: [],
    },
    computed: {
      marmaraAmountStatByBlocksDiff: [],
      marmaraGroupBlocksByDay: {},
      marmaraAmountStatDaily: {},
    },
  };
  this.computedStats = {
    '7d': {},
    '30d': {},
    '90d': {},
    'all': {},
  };
  this.currentBlock = 0;
  this.lastBlockChecked = 1;
  this.statsSyncInProgress = false;
  this.dataDumpInProgress = false;
  this.lastBlockStatsProcessed = 0;
}

StatsController.prototype.showStatsSyncProgress = function(req, res) {
  res.jsonp({
    info: {
      chainTip: this.currentBlock,
      lastBlockChecked: this.lastBlockChecked,
      progress: Number(this.lastBlockChecked * 100 / this.currentBlock).toFixed(2),
    }
  });
};

StatsController.prototype.kickStartStatsSync = function() {
  // ref: https://github.com/pbca26/komodolib-js/blob/interim/src/time.js
  var currentEpochTime = Date.now() / 1000;
  var secondsElapsed = Number(currentEpochTime) - Number(this.lastBlockStatsProcessed / 1000);

  if (Math.floor(secondsElapsed) > 60) {
    this.node.log.info('kickstart stats sync');
    this.statsSyncInProgress = false;
  }
};

StatsController.prototype.startSync = function() {
  var self = this;

  try {
    var localCacheRaw = fs.readFileSync(self.statsPathRaw, 'UTF-8');
    this.cache.raw = JSON.parse(localCacheRaw);
    this.lastBlockChecked = this.cache.raw.marmaraAmountStatByBlocks[this.cache.raw.marmaraAmountStatByBlocks.length - 1].height + 1;
    var localCacheComputed = fs.readFileSync(self.statsPathComputed, 'UTF-8');
    this.cache.computed = JSON.parse(localCacheComputed);
    if (!this.cache.computed.hasOwnProperty('marmaraAmountStatDaily')) this.cache.computed.marmaraAmountStatDaily = {};
  } catch (e) {
    self.node.log.info(e);
  }

  this.node.services.bitcoind.getInfo(function(err, result) {
    if (!err) {
      self.node.log.info('sync getInfo', result);
      self.currentBlock = result.blocks;
      self.node.log.info('stats sync: ' + self.statsSyncInProgress);
      if (!self.statsSyncInProgress) self.syncStatsByHeight();
    }
  });

  setInterval(() => {
    this.node.services.bitcoind.getInfo(function(err, result) {
      if (!err) {
        self.node.log.info('sync getInfo', result);
        self.currentBlock = result.blocks;
        self.kickStartStatsSync();
        self.node.log.info('stats sync: ' + self.statsSyncInProgress);
        if (!self.statsSyncInProgress) self.syncStatsByHeight();
      }
    });
  }, TIP_SYNC_INTERVAL * 1000);

  this.generateDaysStats();

  setInterval(() => {
    if (!self.dataDumpInProgress) {
      fs.writeFile(self.statsPathRaw, JSON.stringify(self.cache.raw), function (err) {
        if (err) self.node.log.info(err);
        self.node.log.info('marmara raw stats file updated');
      });

      fs.writeFile(self.statsPathComputed, JSON.stringify(self.cache.computed), function (err) {
        if (err) console.log(err);
        self.node.log.info('marmara computed stats file updated');
      });
    }
  }, 5 * 1000);
};

StatsController.prototype.syncStatsByHeight = function() {
  var self = this;
  self.node.log.info('marmara sats sync start at ht. ' + self.lastBlockChecked);

  var checkBlock = function(height) {
    if (height < self.currentBlock) {
      self.statsSyncInProgress = true;
      self.lastBlockStatsProcessed = Date.now();

      self.node.services.bitcoind.getBlockOverview(height, function(err, block) {
        if (!err) {
          //self.node.log.info(block);
          
          self.node.services.bitcoind.marmaraAmountStat(height, height, function(err, result) {
            if (!err) {
              //self.node.log.info('sync marmaraAmountStat ht.' + height, result);

              self.cache.raw.marmaraAmountStatByBlocks.push({
                height: result.BeginHeight,
                TotalNormals: result.TotalNormals,
                TotalPayToScriptHash: result.TotalPayToScriptHash,
                TotalActivated: result.TotalActivated,
                TotalLockedInLoops: result.TotalLockedInLoops,
                TotalUnknownCC: result.TotalUnknownCC,
                SpentNormals: result.SpentNormals,
                SpentPayToScriptHash: result.SpentPayToScriptHash,
                SpentActivated: result.SpentActivated,
                SpentLockedInLoops: result.SpentLockedInLoops,
                SpentUnknownCC: result.SpentUnknownCC,
                time: block.time,
              });
              
              if (height > 1) {
                self.node.log.info('marmara calc stat diff at ht.cur ' + height + ' ht.prev ' + (height - 1));

                self.cache.computed.marmaraAmountStatByBlocksDiff.push({
                  height: result.BeginHeight,
                  TotalNormals: self.cache.computed.marmaraAmountStatByBlocksDiff[height - 2].TotalNormals - result.SpentNormals + result.TotalNormals,
                  TotalPayToScriptHash: self.cache.computed.marmaraAmountStatByBlocksDiff[height - 2].TotalPayToScriptHash - result.SpentPayToScriptHash + result.TotalPayToScriptHash,
                  TotalActivated: self.cache.computed.marmaraAmountStatByBlocksDiff[height - 2].TotalActivated - result.SpentActivated + result.TotalActivated,
                  TotalLockedInLoops: self.cache.computed.marmaraAmountStatByBlocksDiff[height - 2].TotalLockedInLoops - result.SpentLockedInLoops + result.TotalLockedInLoops,
                  time: block.time,
                });

              } else {
                self.cache.computed.marmaraAmountStatByBlocksDiff.push({
                  height: result.BeginHeight,
                  TotalNormals: result.TotalNormals,
                  TotalPayToScriptHash: result.TotalPayToScriptHash,
                  TotalActivated: result.TotalActivated,
                  TotalLockedInLoops: result.TotalLockedInLoops,
                  time: block.time,
                });
              }
              
              if (height > 2) self.generateStatsTotals();
              self.lastBlockChecked++;
              checkBlock(self.lastBlockChecked);
            }
          });
        }
      });
    } else {
      self.statsSyncInProgress = false;
    }
  }

  checkBlock(self.lastBlockChecked);
}

StatsController.prototype.generateStatsTotals = function() {
  var self = this;

  var blockDate = new Date(new Date(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1].time * 1000).getFullYear() + '-' + (new Date(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1].time * 1000).getMonth() + 1 < 10 ? ( '0' + (new Date(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1].time * 1000).getMonth() + 1)) : new Date(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1].time * 1000).getMonth() + 1) + '-' + new Date(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1].time * 1000).getDate()).toISOString().substr(0, 10);

  if (!this.cache.computed.marmaraGroupBlocksByDay[blockDate]) this.cache.computed.marmaraGroupBlocksByDay[blockDate] = [];
  this.cache.computed.marmaraGroupBlocksByDay[blockDate].push(this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1]);
  this.cache.computed.marmaraAmountStatDaily[blockDate] = this.cache.computed.marmaraGroupBlocksByDay[blockDate][this.cache.computed.marmaraGroupBlocksByDay[blockDate].length - 1];
  this.generateDaysStats();
};

StatsController.prototype.generateDaysStats = function() {
  var dailyStatsArr = Object.keys(this.cache.computed.marmaraAmountStatDaily);

  for (var r = 0; r < chartRangeEnum.length; r++) {
    var slicedDailyStatsArr = dailyStatsArr.slice(chartRangeEnum[r].number !== 777 ? dailyStatsArr.length - chartRangeEnum[r].number : 0, dailyStatsArr.length);

    for (var a = 0; a < valueEnum.length; a ++) {
      var statsDateArr = [];
      var statsValueArr = [];

      for (var i = 0; i < slicedDailyStatsArr.length; i++) {
        var date = new Date(Date.parse(slicedDailyStatsArr[i]));
        statsDateArr.push(date.getFullYear() + '-' + (date.getMonth() + 1 < 10 ? '0' + (date.getMonth() + 1).toString() : date.getMonth() + 1) + '-' + (date.getDate() < 10 ? '0' + date.getDate() : date.getDate()));
        statsValueArr.push(this.cache.computed.marmaraAmountStatDaily[slicedDailyStatsArr[i]][valueEnum[a]]);
      }
      
      if (statsDateArr.length && statsValueArr.length) {
        this.computedStats[chartRangeEnum[r].name][valueEnum[a]] = {
          date: statsDateArr,
          value: statsValueArr,
        };
      }
    }
    
    this.node.log.info(chartRangeEnum[r].title + ' stats generated');
  }
}

StatsController.prototype.show30DaysStats = function(req, res) {
  var self = this;
  var type = req.query.type;

  if (Object.keys(this.computedStats['30d']).length) {
    if (Object.keys(this.computedStats).indexOf(type) > -1) {
      res.jsonp({
        info: this.computedStats[type]
      });
    } else {
      res.jsonp({
        info: {
          TotalNormals: this.computedStats['30d'].TotalNormals,
          TotalActivated: this.computedStats['30d'].TotalActivated,
          TotalLockedInLoops: this.computedStats['30d'].TotalLockedInLoops
        }
      });
    }
  } else {
    res.jsonp({
      error: 'syncing stats'
    });
  }
};

StatsController.prototype.showStats = function(req, res) {
  var result = this.cache.computed.marmaraAmountStatByBlocksDiff[this.cache.computed.marmaraAmountStatByBlocksDiff.length - 1];

  res.jsonp({
    info: result
  });
};

StatsController.prototype.dumpStatsData = function() {  
  this.dataDumpInProgress = true;
  fs.writeFileSync(this.statsPathRaw, JSON.stringify(this.cache.raw));
  fs.writeFileSync(this.statsPathComputed, JSON.stringify(this.cache.computed));
  this.node.log.info('stats on node stop, dumped data');
};

module.exports = StatsController;
