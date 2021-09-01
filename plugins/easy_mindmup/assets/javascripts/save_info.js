/**
 * Created by hosekp on 1/23/17.
 */
(function () {
  /**
   *
   * @param {MindMup} ysy
   * @property {MindMup} ysy
   * @property {jQuery} $parent
   * @property {jQuery} $element
   * @property {Date} lastTime
   * @property {string} state
   * @constructor
   */
  function SaveInfo(ysy) {
    this.ysy = ysy;
    this.init(ysy);
    this.state = 'initial';
    this.lastTime = new Date();
  }

  /**
   * @private
   * @param {MindMup} ysy
   */
  SaveInfo.prototype.init = function (ysy) {
    this.$parent = ysy.toolbar.$menu;
    ysy.toolbar.addChild(this);
    this.$element = this.$parent.find(".mindmup__menu-save");
    if (window.moment) {
      var self = this;
      this.interval = window.setInterval(function () {
        ysy.repainter.redrawMe(self);
      }, 60 * 1000);
    }
  };
  /**
   *
   * @param {String} saveState
   */
  SaveInfo.prototype.saveFinished = function (saveState) {
    if (!this.$element.length) return;
    this.lastTime = new Date();
    this.state = saveState === "classic" ? "saved" : "autosaved";
    this.ysy.repainter.redrawMe(this);
  };

  SaveInfo.prototype._render = function () {
    if (!this.$element.length) return;
    var rendered;
    var labels = this.ysy.settings.labels.save_info;
    if (window.moment) {
      rendered = labels[this.state] + " " + moment(this.lastTime).fromNow();
    } else {
      rendered = labels[this.state] + " " + labels["at"] + " " + this.lastTime.toTimeString().split(" ")[0];
    }
    this.$element.attr("title", rendered);
  };

  window.easyMindMupClasses.SaveInfo = SaveInfo;
  //####################################################################################################################
})();