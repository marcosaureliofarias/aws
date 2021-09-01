(function () {
  /**
   * Autosave feature - there are three phases - long, render and short
   * 'hidden' period is there for off-screen detection to prevent saving in background
   * In 'short' period, any user action triggers Save.
   *
   * @param {MindMup} ysy
   * @property {String} phase
   * @property {MindMup} ysy
   * @property {number} shortTimeout
   * @property {number} longTimeout
   * @constructor
   */
  function Autosave(ysy) {
    this.phase = null;
    this.ysy = ysy;
    this.shortTimeout = 0;
    this.longTimeout = 0;
    this.init();
    this.initVisibility();
  }

  Autosave.prototype.testing = false;
  Autosave.prototype.longPeriod = 10 * 60 * 1000;
  Autosave.prototype.shortPeriod = 2 * 60 * 1000;
  // Autosave.prototype.testing = true;
  // Autosave.prototype.longPeriod = 3 * 1000;
  // Autosave.prototype.shortPeriod = 2 * 1000;

  Autosave.prototype.init = function () {
    var self = this;
    var ysy = this.ysy;
    /** called when change in mindMap is detected and at the end of short period */
    var changeWatcher = function () {
      if (self.phase !== 'short') return;
      // probably unnecessary, but can prevent multiple firing
      ysy.idea.removeEventListener('changed', self.changeWatcher);
      if (self.testing) {
        ysy.log.debug(new Date().toISOString() + " saving", "autosave");
        startLongPhase(); // "TreeLoaded" event already calls startLongPhase()
      } else {
        ysy.saver.save("autosave");
      }
    };
    this.changeWatcher = changeWatcher;

    var startShortPhase = function () {
      if (self.phase === 'short') return;
      if (self.longTimeout) {
        window.clearTimeout(self.longTimeout);
        self.longTimeout = 0;
      }
      self.phase = 'short';
      ysy.log.debug("short period", "autosave");
      ysy.idea.removeEventListener('changed', changeWatcher);
      ysy.idea.addEventListener('changed', changeWatcher);
      self.shortTimeout = setTimeout(changeWatcher, self.shortPeriod);
    };
    var startLongPhase = function () {
      if (self.shortTimeout) {
        window.clearTimeout(self.shortTimeout);
        self.shortTimeout = 0;
      }
      if (self.longTimeout) {
        window.clearTimeout(self.longTimeout);
      }
      self.phase = 'long';
      ysy.log.debug("long period", "autosave");
      self.longTimeout = setTimeout(startShortPhase, self.longPeriod);
    };
    if (this.testing) {
      this.startLongPhase = startLongPhase;
    }

    ysy.eventBus.register("IdeaConstructed", function () {
      startLongPhase();
    });
  };
  Autosave.prototype.initVisibility = function () {
    var hiddenKey = "hidden";
    var visibilityChangeName = "visibilitychange";
    if (typeof document.hidden === "undefined") {
      if (typeof document.msHidden !== "undefined") {
        hiddenKey = "msHidden";
        visibilityChangeName = "msvisibilitychange";
      } else if (typeof document.webkitHidden !== "undefined") {
        hiddenKey = "webkitHidden";
        visibilityChangeName = "webkitvisibilitychange";
      } else {
        return;
      }
    }
    var self = this;
    var ysy = this.ysy;
    var handleVisibilityChange = function () {
      if (!document[hiddenKey]) {
        window.clearTimeout(self.shortTimeout);
        window.clearTimeout(self.longTimeout);
        ysy.log.debug("off-site period", "autosave");
        if (self.testing) {
          ysy.log.debug(new Date().toISOString() + " saving by off-site", "autosave");
        } else {
          ysy.saver.save("off-site");
        }
      } else {
        if (self.testing) {
          ysy.log.debug(new Date().toISOString() + " loading by off-site", "autosave");
          self.startLongPhase();
        }
      }
    };
    $(document).on(visibilityChangeName, handleVisibilityChange);
  };
  window.easyMindMupClasses.Autosave = Autosave;
})();
