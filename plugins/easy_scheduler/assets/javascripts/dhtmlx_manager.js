window.EasyCalendar = window.EasyCalendar || {};
(function () {
  /**
   * @callback DhtmlxManagerBody
   * @param {{scheduler:Object,modalOptions:Object}} instance
   */

  /**
   * @class
   * @constructor
   */
  function DhtmlxManager() {
    this._plugins = {};
    this._addons = {};
    this.instances = {};
  }
  /**
   * Register toggleable plugin with functionality
   * @param {string} pluginName
   * @param {DhtmlxManagerBody} body
   */
  DhtmlxManager.prototype.registerPlugin = function (pluginName, body) {
    this._plugins[pluginName] = body;
  };
  /**
   * Register patch to plugin (can't be turn off)
   * @param {string} pluginName
   * @param {DhtmlxManagerBody} body
   */
  DhtmlxManager.prototype.registerAddOn = function (pluginName, body) {
    if (!this._addons[pluginName]) {
      this._addons[pluginName] = [];
    }
    this._addons[pluginName].push(body);
  };
  /**
   * Construct scoped DHTMLX component
   * @param {string} id
   * @param {Array.<string>} plugins
   * @param {DhtmlxManagerBody} afterCallback
   */
  DhtmlxManager.prototype.construct = function (id, plugins, afterCallback) {
    plugins = plugins || Object.keys(this._plugins);
    plugins = plugins.filter(function (p) {
      return p;
    });
    var self = this;
    EasyGem.schedule.require(function () {
      var instance = {id: id};
      for (var i = 0; i < plugins.length; i++) {
        var pluginName = plugins[i];
        self._plugins[pluginName](instance);
        if (self._addons[pluginName]) {
          var addons = self._addons[pluginName];
          for (var j = 0; j < addons.length; j++) {
            addons[j].call(window, instance);
          }
        }
      }
      self.instances[id] = instance;
      afterCallback.call(window, instance);
    }, function () {
      return self.haveAllPlugins(plugins);
    });
    setTimeout(function () {
      var missing = [];
      for (var i = 0; i < plugins.length; i++) {
        if (!self._plugins[plugins[i]]) {
          missing.push(plugins[i]);
        }
      }
      if (missing.length === 0) return;
      console.error("DhtmlxManager: missing: " + missing.join(", "));
    }, 5000);
  };
  DhtmlxManager.prototype.haveAllPlugins = function (plugins) {
    for (var i = 0; i < plugins.length; i++) {
      if (!this._plugins[plugins[i]]) return false;
    }
    return true;
  };
  window.EasyCalendar.manager = new DhtmlxManager();

  //####################################################################################################################
})();

