(function () {
  /**
   * @class
   * @constructor
   * @param {CalendarMain} main
   * @property {CalendarMain} main
   */
  function CalendarTests(main) {
    this.main = main;
    this.fakeStorage = {
      "primary-assignee": "24",
      "selected-assignees": "[24, 1]"
    };
    main.eventBus.register("loaded", function () {
      jasmineHelper.unlock("data");
    });
    main.eventBus.register("tasksLoaded", function () {
      jasmineHelper.unlock("tasks");
    });
    var self = this;
    main.eventBus.register("schedulerInited", function (scheduler) {
      scheduler.getFromStorage = function (key) {
        return self.fakeStorage[key];
      };
      scheduler.saveToStorage = function (key, value) {
        return self.fakeStorage[key] = value;
      };
    });
    main.assigneeData.currentId = 1;
    main.assigneeData.primaryId = 1;
    var firstView = null;
    jasmine.getEnv().addReporter({
      jasmineDone: function () {
        if (!firstView) return;
        main.scheduler.setCurrentView(firstView.date, firstView.zoom);
        firstView = null;
      }
    });
    this.setView = function (date, zoom) {
      var scheduler = main.scheduler;
      var oldDate = scheduler._min_date;
      var oldZoom = scheduler._mode;
      if (!firstView) {
        firstView = {date: oldDate, zoom: oldZoom};
      }
      if (zoom === oldZoom && oldDate.valueOf() === new Date(date).valueOf()) return;
      scheduler.setCurrentView(new Date(date), zoom);
    };
    main.externalDnD.extendDelay = 0;
  }

  EasyCalendar.CalendarTests = CalendarTests;
  // $("body").mousemove(function (e) {
  //   window.printout(JSON.stringify({x: e.pageX, y: e.pageY}), 4);
  // });
})();
