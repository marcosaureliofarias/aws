/* utils.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.main = ysy.main || {};
EasyGem.extend(ysy.main, {
  extender: function (parent, child, proto) {
    function ProtoCreator() {
    }
    ProtoCreator.prototype = parent.prototype;
    child.prototype = new ProtoCreator();
    child.prototype.constructor = child;
    EasyGem.extend(child.prototype, proto);
  },
  getModal: function (id, width) {
    var $target = $("#" + id);
    if ($target.length === 0) {
      $target = $("<div id=" + id + ">");
      $target.dialog({
        width: width,
        appendTo: document.body,
        modal: true,
        resizable: false,
        dialogClass: 'modal',
        position: { my: 'top', at: 'top' }
      });
      $target.dialog("close");
    }
    return $target;
  },
  toMomentFormat: function (rubyFormat) {
    switch (rubyFormat) {
      case '%Y-%m-%d':
        return 'YYYY-MM-DD';
      case '%Y/%m/%d':
        return 'YYYY/MM/DD';
      case '%d/%m/%Y':
        return 'DD/MM/YYYY';
      case '%d.%m.%Y':
        return 'DD.MM.YYYY';
      case '%d-%m-%Y':
        return 'DD-MM-YYYY';
      case '%m/%d/%Y':
        return 'MM/DD/YYYY';
      case '%d %b %Y':
        return 'DD MMM YYYY';
      case '%d %B %Y':
        return 'DD MMMM YYYY';
      case '%b %d, %Y':
        return 'MMM DD, YYYY';
      case '%B %d, %Y':
        return 'MMMM DD, YYYY';
      default:
        return 'D. M. YYYY';
    }
  },
  startsWith: function (text, char) {
    if (text.startsWith) {
      return text.startsWith(char);
    }
    return text.toString().charAt(0) === char;
  },
  isSameMoment: function (date1, date2) {
    if (!moment.isMoment(date1)) return false;
    if (!moment.isMoment(date2)) return false;
    return date1.isSame(date2);
  },
  /**
   * Utility function for measuring performance of some code
   * @example
   * var perf = createPerformanceMeter("myFunction");
   * perf("part 1");
   * perf("part 2");
   * perf.whole();
   * @param {String} groupName
   * @return {Function}
   */
  createPerformanceMeter: function (groupName) {
    var lastTime = window.performance.now();
    var silence = false;
    var initTime = lastTime;
    var func = function (/** @param {String} name*/ name) {
      if (silence) return;
      var nowTime = window.performance.now();
      var nameString = groupName + " " + name + ":                                  ";
      nameString = nameString.substr(0, 30);
      var diffString = "        " + (nowTime - lastTime).toFixed(3);
      diffString = diffString.substr(diffString.length - 10);
      console.debug(nameString + diffString + " ms");
      lastTime = nowTime;
    };
    func.whole = function () {
      if (silence) return;
      var nowTime = window.performance.now();
      var nameString = groupName + ":                                  ";
      nameString = nameString.substr(0, 30);
      var diffString = "        " + (nowTime - initTime).toFixed(3);
      diffString = diffString.substr(diffString.length - 10);
      console.debug(nameString + diffString + " ms");
    };
    func.silence = function (verbose) {
      silence = !verbose;
    };
    return func;
  },
  /**
   *
   * @param {Array.<{name:String,value:String}>} formData
   * @return {Object}
   */
  formToJson: function (formData) {
    var result = {};
    var prolong = function (result, split, value) {
      var key = split.shift();
      if (key === "") {
        result.push(value);
      } else {
        if (split.length > 0) {
          var next = split[0];
          if (!result[key]) {
            if (next === "") {
              result[key] = [];
            } else {
              result[key] = {};
            }
          }
          prolong(result[key], split, value);
        } else {
          // If its a number in a string change it to pure number
         if(!isNaN(value) && value.length) {
           value = +value;
         }
          result[key] = value;
        }
      }
    };
    for (var i = 0; i < formData.length; i++) {
      var split = formData[i].name.split(/]\[|\[|]/);
      if (split.length > 1) {
        split.pop();
      }
      prolong(result, split, formData[i].value);
    }
    return result;
  },
  escapeText: function (text) {
    var tmp = document.createElement('div');
    tmp.appendChild(document.createTextNode(text));
    return tmp.innerHTML;
  },

  // Change first day of week on current locale depending on user setting or to monday
  setFirstDayOfWeek: function () {
    moment.updateLocale(moment().locale(), {
      week: {
        dow: EASY.datepickerOptions.firstDay || 1,
      }
    });
  },

  /***
   *
   * @param {string} resourcesSums
   * @private
   */
  _resourcesStringToFloat: function (resourcesSums) {
    if (resourcesSums.length === 0) return;
    for (var resourceDate in resourcesSums) {
      if (!resourcesSums.hasOwnProperty(resourceDate)) continue;
      resourcesSums[resourceDate] = parseFloat(resourcesSums[resourceDate]);
    }
  },

  /***
   *
   * @param {object} resourcesSums
   * @private
   */
  _resourcesObjectToFloat: function (resourcesSums) {
    if (resourcesSums.length === 0) return;
    for (var resourceDate in resourcesSums) {
      if (!resourcesSums.hasOwnProperty(resourceDate)) continue;
      if (!resourcesSums[resourceDate].hasOwnProperty('hours')) continue;
      resourcesSums[resourceDate].hours = parseFloat(resourcesSums[resourceDate].hours);
    }
  },
    /***
   *
   * @param {key} local storage key,
   * @param {value} return value
   */
  checkForStorageValue: function (key, value) {
    let isActive = value;
    if (JSON.parse(ysy.data.storage.getPersistentData(key))) {
      isActive = JSON.parse(ysy.data.storage.getPersistentData(key));
    }
    return isActive;
  }
});
