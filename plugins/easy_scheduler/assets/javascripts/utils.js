(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {CalendarMain} main
   */
  function Utils(main) {
    this.main = main;
    this.normalizeRootPath(main.settings.paths);
  }

  /**
   * @memberOf Utils
   * @param {string} text
   * @param {number} [timeout]
   */
  Utils.prototype.showError = function (text, timeout) {
    showFlashMessage("error", text, timeout);
  };
  /**
   * @memberOf Utils
   * @param {string} text
   * @param {number} timeout
   */
  Utils.prototype.showNotice = function (text, timeout) {
    showFlashMessage("notice", text, timeout);
  };
  Utils.prototype.showLastSaveAtMsg = function (text) {
    var $heading = this.main.$container.prevAll().find(".easy-query-heading");
    if (!$heading.length) return;
    var $element = $heading.parent().find(".last-saved-time-stamp");
    if (!$element.length) {
      $element = $("<div/>", {
        class: "fixed last-saved-time-stamp text-center color-positive"
      }).insertAfter($heading);
    }
    $element.html(text);
    return $element;
  };

  Utils.prototype.updateEvent = function () {};
  Utils.prototype.normalizeRootPath = function (paths) {
    if (paths.rootPath === "/") {
      paths.rootPath = "";
    }
  };
  /**
   * @memberOf Utils
   * @param {String} text
   * @param {String} char
   * @return {boolean}
   */
  Utils.prototype.startsWith = function (text, char) {
    if (text.startsWith) {
      return text.startsWith(char);
    }
    return text.charAt(0) === char;
  };
  /**
   * @memberOf Utils
   * @param object
   * @return {Array.<Object>}
   */
  Utils.prototype.objectValues = function (object) {
    var keys = Object.keys(object);
    return keys.map(function (key) {
      return object[key];
    });
  };
  /**
   * @memberOf Utils
   * @param {Date} endDate
   * @return {Date|null}
   */
  Utils.prototype.fixEndDate = function (endDate) {
    if (!endDate) return null;
    var date = new Date(endDate.valueOf());
    date.setDate(date.getDate() + 1);
    return date;
  };
  /***
   * @memberOf Utils
   * @param {string} date
   * @return {*}
   */
  Utils.prototype.parseDate = function (date) {
    if (window.EASY && EASY.utils && EASY.utils.parseDate ) {
      return EASY.utils.parseDate(date);
    }
    console.error("You don't have access to a function: EASY.utils.parseDate");
    return new Date(date);
  };
  var consoleElement = document.createElement("DIV");
  consoleElement.style.position = "absolute";
  consoleElement.style.top = "53px";


  EasyCalendar.Utils = Utils;
})();
