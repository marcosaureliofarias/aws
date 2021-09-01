EasyCalendar.manager.registerPlugin("localstorage", function (instance) {
  var scheduler = instance.scheduler;
  var mainKey = instance.id;
  /**
   * @param {string} key
   * @return {string | null}
   */
  scheduler.getFromStorage = function (key) {
    return localStorage.getItem(mainKey + "-" + key);
  };
  /**
   * @param {string} key
   * @param {string} value
   */
  scheduler.saveToStorage = function (key, value) {
    return localStorage.setItem(mainKey + "-" + key, value);
  };
  /***
   * @param {Array.<string>} keys
   */
  scheduler.deleteFromStorage = function (keys) {
    for (var i = 0; i < keys.length; i++) {
      localStorage.removeItem(mainKey + "-" + keys[i]);
    }
  }
});