(function () {
  var classes = window.easyMindMupClasses;

  /**
   * @extends {NodePatch}
   * @param {WbsMain} ysy
   * @constructor
   */
  function WbsStorage(ysy) {
    this.ysy = ysy;
    classes.Storage.call(this, ysy);
    this.patch(ysy);
  }

  classes.extendClass(WbsStorage, classes.Storage);

  WbsStorage.prototype.patch = function (ysy) {
    var self = this;
    var rootId = this.ysy.settings.rootID;
    ysy.eventBus.register("budgetToggled", function (opened) {
      self.settings._save({budgetIsOn: opened}, false, rootId);
    });
    ysy.eventBus.register("cumulativeTypeToggled", function (active) {
      self.settings._save({cumulativeTasks: active}, false, rootId);
    });

    this.settings.loadBudget = function () {
      return this._load("budgetIsOn", rootId);
    };

    this.settings.loadCumulativeType = function () {
      return this._load("cumulativeTasks", rootId);
    };
  };

  classes.WbsStorage = WbsStorage;
})();
