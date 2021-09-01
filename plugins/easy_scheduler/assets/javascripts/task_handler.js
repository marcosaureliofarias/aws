(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   */
  function TaskHandler(main) {
    this.init(main);
  }

  TaskHandler.prototype.init = function (main) {
    main.eventBus.register("taskChanged", function (task, key, value) {
      if (key === "assigned_to_id") {
        var scheduler = main.scheduler;
        task.getMyEvents().forEach(function (event) {
          if (event.type === "allocation" && event.user_id !== value) {
            scheduler.deleteEvent(event.id);
          }
        });
      }
    });
    main.eventBus.register("eventChanged", function (event) {
      var task = main.taskData.getTaskById(event.issue_id, 'issues');
      if (task) {
        if (!task._haveAllocations) {
          task._haveAllocations = true;
        }
        main.eventBus.fireEvent("taskChanged", task);
      }
    });
    main.eventBus.register("schedulerInited", function (scheduler) {
      scheduler.attachEvent("onDragEnd", function (id, mode/*, mouseEvent*/) {
        if (mode !== "resize") return;
        var event = scheduler.getEvent(id);
        if (!event) return;
        var task = main.taskData.getTaskById(event.issue_id, 'issues');
        if (!task) return;
        task.fixRestEstimated();
      })
    });
  };
  EasyCalendar.TaskHandler = TaskHandler;
})();
