(function () {
  /**
   * Asynchronic redrawer
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {CalendarMain} main
   * @property {CalendarRepainter} _calendarRepainter
   */
  function Repainter(main) {
    this.main = main;
    this._calendarRepainter = new CalendarRepainter(main);
    this.onRepaint = [];
    var self = this;
    var animationLoop = function () {
      var queue = self.onRepaint;
      if (queue.length > 0) {
        self.onRepaint = [];
        for (var i = 0; i < queue.length; i++) {
          var widget = queue[i];
          widget._redrawRequested = false;
          widget._render();
        }
      }
      requestAnimationFrame(animationLoop);
    };
    this.animationLoop = animationLoop;
  }

  Repainter.prototype.start = function () {
    this.animationLoop();
  };
  /**
   * Main function - insert widget into repaint queue (if not present there)
   * @param {Object} widget
   * @methodOf Repainter
   */
  Repainter.prototype.redrawMe = function (widget) {
    if (!widget) return;
    if (!widget && widget._redrawRequested) return;
    widget._redrawRequested = true;
    this.onRepaint.push(widget);
  };
  /**
   * @param {boolean} [updateView]
   * @methodOf Repainter
   */
  Repainter.prototype.repaintCalendar = function (updateView) {
    if (updateView) {
      this._calendarRepainter.updateView = true;
    }
    this.redrawMe(this._calendarRepainter);
  };
  window.EasyCalendar.Repainter = Repainter;

  //####################################################################################################################
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {CalendarMain} main
   */
  function CalendarRepainter(main) {
    this.main = main;
    var self = this;
    main.eventBus.register("assigneeChanged", function () {
      main.repainter.redrawMe(self);
    });
    ResizeSensor(main.$container, function () {
      main.eventBus.fireEvent("resize");
      main.repainter.repaintCalendar(true);
    });
  }

  CalendarRepainter.prototype._render = function () {
    if (this.updateView) {
      this.updateView = false;
      this.main.scheduler.update_view();
    } else {
      this.main.scheduler.render_view_data();
    }
  }
})();
