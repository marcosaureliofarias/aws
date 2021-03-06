(function () {
  function Logger() {
    this.logLevel = 2;
    this.mainDebug = "";
    this.debugTypes = [
      "updateDropper",
      "nothing"
    ];
  }

  /**
   * @memberOf Logger
   * @param {String} text
   */
  Logger.prototype.log = function (text) {
    if (this.logLevel >= 4) {
      this.print(text);
    }
  };
  /**
   * @memberOf Logger
   * @param {String} text
   */
  Logger.prototype.message = function (text) {
    if (this.logLevel >= 3) {
      this.print(text);
    }
  };
  /**
   * @memberOf Logger
   * @param {String} text
   * @param {String} [type]
   */
  Logger.prototype.debug = function (text, type) {
    if (type) {
      if (this.mainDebug === type) {
        this.print(text, "debug");
        return;
      }
      for (var i = 0; i < this.debugTypes.length; i++) {
        if (this.debugTypes[i] === type) {
          this.print(text, type === this.mainDebug ? "debug" : null);
          return;
        }
      }
    } else {
      this.print(text, "debug");
    }
  };
  Logger.prototype.warning = function (text) {
    if (this.logLevel >= 2) {
      this.print(text, "warning");
    }
  };
  Logger.prototype.error = function (text) {
    if (this.logLevel >= 1) {
      this.print(text, "error");
    }
  };
  Logger.prototype.print = function (text, type) {
    if (type === "error") {
      console.error(text);
    } else if (type === "warning") {
      console.warn(text);
    } else if (type === "debug") {
      console.debug(text);
    } else {
      console.log(text);
    }
  };
  EasyCalendar.Logger = Logger;
})();
