(function () {
  /** @typedef {{left:int,top:int,right:int,bottom:int,element:HtmlElement}} DroppableTarget

   /**
   * @class
   * @constructor
   * @param {CalendarMain} main
   * @property {CalendarMain} main
   * property {jQuery} $dropper
   * property {{id:int}} droppedEvent
   * property {int} droppedDate
   * property {Assignee} droppedAssignee
   */
  function ExternalDnD (main) {
    this.main = main;
    main.eventBus.register("schedulerInited", $.proxy(this.init, this));
  }

  ExternalDnD.prototype.extendDelay = 2500;
  ExternalDnD.prototype.temp = null;

  ExternalDnD.prototype.init = function (scheduler) {
  };
  /**
   * @param {TaskView} taskView
   */
  ExternalDnD.prototype.mouseDownBind = function (taskView) {
    var task = taskView.task;
    var self = this;
    taskView.$cont.off("mousedown.external_dnd touchstart.external_dnd").on("mousedown.external_dnd touchstart.external_dnd", function (event) {
      var noDrag = true;
      var swipe = false;
      var extendTimeout = null;
      var extendEvent = null;
      if (event.type === "touchstart") {
        var touchTime = new Date();
        var touch = event.originalEvent.touches[0] || event.originalEvent.changedTouches[0];
        var originX = touch.pageX;
        var originY = touch.pageY;
      } else {
        originX = event.pageX;
        originY = event.pageY;
      }
      // console.log("MouseDown on "+originX+" "+originY);
      var $body = $("body");
      var droppableTargets = [];
      var activeButtonOn = false;
      var userFilter = function (event) {
        var userId = self.temp.assignee && self.temp.assignee.id;
        if (event.user_id === userId) return true;
        if (event.user_ids) {
          return event.user_ids.indexOf(userId) > -1;
        }
        return false;
      };
      // #########  MOUSEMOVE  ##########################################################################################
      var mousemove = function (event) {
        if (swipe) return;
        if (event.type === "touchmove") {
          var touch = event.originalEvent.touches[0] || event.originalEvent.changedTouches[0];
          var pageX = touch.pageX;
          var pageY = touch.pageY;
        } else {
          pageX = event.pageX;
          pageY = event.pageY;
        }
        // console.log("MouseMove on "+pageX+" "+pageY);
        if (noDrag) {
          if (Math.pow(pageX - originX, 2) + Math.pow(pageY - originY, 2) < 100) {
            return;
          }
          if (touchTime && new Date() - touchTime < 100) {
            swipe = true;
            return;
          }
          noDrag = false;
          self.temp = {};
          self.showDroppableAreas(task);
          taskView.lockRender();
          $body.addClass("easy-calendar__body--no-select");
          self.main.eventBus.fireEvent("startExternalDnD", task);
          droppableTargets = self.prepareDroppingTargets();
          self.temp.$dhx_cal_data = self.main.$container.find(".dhx_cal_data");
          self.temp.dataScroll = self.temp.$dhx_cal_data.scrollTop();
          var endLimit = self.main.utils.fixEndDate(task.due_date);
          self.temp.assignee = self.main.assigneeData.getPrimaryUser();
          self.temp.empties = self.main.scheduler.prepareEmptySpaces(userFilter, {
            start: task.start_date,
            end: endLimit
          });
          if (task.assigned_to_id === self.temp.assignee.id) {
            var hours = task.getRestEstimated();
          } else {
            hours = task.estimated_hours - task.spent_hours;
            task._exceptEventIds = task.getMyEvents().map(function (event) {
              return event.id.toString();
            });
          }
          hours = Math.round(hours * 100) / 100;
          self.temp.restMillis = hours * 3600000;
          self.temp.droppedEvents = [];
        }
        event.preventDefault();
        event.stopPropagation();
        /** @type {DroppableTarget} */
        var target = self.findDroppableTarget(pageX, pageY, droppableTargets);
        if (target) {
          if (target !== self.temp.lastTarget) {
            self.temp.lastTarget = target;
            self.temp.lastTargetTime = new Date();
            clearTimeout(extendTimeout);
            extendTimeout = null;
          }
          var element = target.element;
          var $element = $(element);
          var className = $element[0].className;
          if (className.indexOf("easy-calendar__month-cell") > -1) {
            $element = $element.find(".dhx_month_body");
          }
          if (className.indexOf("easy-calendar__active-button") > -1) {
            if (!activeButtonOn) {
              activeButtonOn = true;
              $element.click();
              droppableTargets = self.prepareDroppingTargets();
              endLimit = self.main.utils.fixEndDate(task.due_date);
              self.temp.empties = self.main.scheduler.prepareEmptySpaces(userFilter, {
                start: task.start_date,
                end: endLimit
              });
            }
            return;
          }
          activeButtonOn = false;
          var elementData = $element.data();
          self.updateWrongDrop(false);
          if (elementData) {
            const allocationEndDate = new Date(elementData.date).setHours(0, 0, 0, 0);
            const inPast = allocationEndDate < new Date().setHours(0, 0, 0, 0);
            const inRange = task.dateInDuration(elementData.date);
            self.temp.$dropper = self.buildDropper(task, inPast, inRange);
            taskView.lockRender();
            $body.addClass("easy-calendar__body--no-select");
            event.preventDefault();
            event.stopPropagation();
            self.temp.$dropper.css({ left: pageX, top: pageY });
              if (inRange && !inPast) {
              var time = self.main.scheduler.config.first_hour * 3600000;
              if ($element.hasClass("easy-calendar__day-cell")) {
                var dataShift = self.temp.$dhx_cal_data.scrollTop() - self.temp.dataScroll;
                var config = self.main.scheduler.config;
                time += Math.round((pageY - target.top + dataShift) / config.hour_size_px * 60 / config.time_step) *
                    config.time_step * 60 * 1000;
              }
              var shouldExtend = (new Date() - self.temp.lastTargetTime) >= self.extendDelay;
              var body = this;
              extendEvent = event;
              if (!shouldExtend && !extendTimeout) {
                extendTimeout = setTimeout(function () {
                  var newEvent = new MouseEvent(extendEvent.type, extendEvent);
                  body.dispatchEvent(newEvent);
                }, self.extendDelay);
              }
              self.updateDroppedTask(task, elementData.date.valueOf() + time, shouldExtend);
              self.updateWrongDrop(false);
              return;
            } else {
              self.updateWrongDrop(true);
            }
          }
        } else {
          self.updateWrongDrop(false);
          activeButtonOn = false;
          self.temp.lastTarget = null;
        }
        return self.updateDroppedTask(null, null, false);
      };
      // $body.on("mousemove.external_dnd touchmove.external_dnd", mousemove);
      $body.on("mousemove.external_dnd", mousemove);
      taskView.$cont.on("touchmove.external_dnd", mousemove);

      // #######  MOUSEUP  ##############################################################################################
      var mouseup = function (event) {
        // $body.off("mousemove.external_dnd touchmove.external_dnd mouseup.external_dnd touchend.external_dnd");
        $body.off("mousemove.external_dnd mouseup.external_dnd");
        taskView.$cont.off("touchmove.external_dnd touchend.external_dnd");
        if (!noDrag) {
          clearTimeout(extendTimeout);
          extendTimeout = null;
          self.removeDropper();
          if (self.temp.droppedEvents.length > 0) {
            task.set("assigned_to_id", self.temp.assignee.id);
            task.fixRestEstimated();
          }
          task._exceptEventIds = null;
          self.temp = null;
          self.hideDroppableAreas();
          self.main.eventBus.fireEvent("endExternalDnD", task);
          taskView.unlockRender();
        } else {
          if (event.type === "touchend") {
            var touch = event.originalEvent.touches[0] || event.originalEvent.changedTouches[0];
            var endPageX = touch.pageX;
            var endPageY = touch.pageY;
          } else {
            endPageX = event.pageX;
            endPageY = event.pageY;
          }
          var moveCoeficient = 100;
          if (Math.pow(endPageX - originX, 2) + Math.pow(endPageY - originY, 2) > moveCoeficient) {
            return;
          }
          taskView.$cont.trigger("no_drag_task_click", event);
        }
      };
      // $body.on("mouseup.external_dnd touchend.external_dnd", mouseup);
      $body.on("mouseup.external_dnd", mouseup);
      taskView.$cont.on("touchend.external_dnd", mouseup);
    });
  };
  /**
   * @returns {Array.<DroppableTarget>}
   */
  ExternalDnD.prototype.prepareDroppingTargets = function () {
    var droppableTargets = [];
    if (window.scrollX === undefined) {
      var scrollTop = document.documentElement.scrollTop;
      var scrollLeft = document.documentElement.scrollLeft;
    } else {
      scrollTop = window.scrollY;
      scrollLeft = window.scrollX;
    }
    var elements = this.main.$container.find(".easy-calendar__day-cell, .easy-calendar__month-cell, .easy-calendar__active-button");
    for (var i = 0; i < elements.length; i++) {
      var box = elements[i].getBoundingClientRect();
      droppableTargets.push({
        left: box.left + scrollLeft,
        top: box.top + scrollTop,
        right: box.right + scrollLeft,
        bottom: box.bottom + scrollTop,
        element: elements[i]
      });
    }
    return droppableTargets;
  };
  ExternalDnD.prototype.updateWrongDrop = function (isOut) {
    if (this.temp.wrongDrop !== isOut) {
      this.temp.wrongDrop = isOut;
      if (this.temp.$dropper) {
        this.temp.$dropper.toggleClass("wrong", isOut);
      }
    }
  };
  /**
   *
   * @param {int} pageX
   * @param {int} pageY
   * @param {Array.<DroppableTarget>} droppableTargets
   * @return {DroppableTarget|null}
   */
  ExternalDnD.prototype.findDroppableTarget = function (pageX, pageY, droppableTargets) {
    for (var i = 0; i < droppableTargets.length; i++) {
      var target = droppableTargets[i];
      if (target.left < pageX && target.right > pageX && target.top < pageY && target.bottom > pageY) {
        return target;
      }
    }
    return null;
  };
  /** @param {Task} task */
  ExternalDnD.prototype.buildDropper = function (task, past, inRange) {
    this.removeDropper();
    const labelOutOfRange = this.main.settings.labels.errorOutOfTaskLimits;
    const labelInThePast = this.main.settings.labels.issueErrors.errorInThePast;
    const label = past && inRange ? labelInThePast : labelOutOfRange;
    return $('<div class="easy-calendar__dropper">' + task.subject.substring(0, 1) +
        '<div class="easy-calendar__dropper_notice">' + label + '</div>').appendTo("body");
  };
  ExternalDnD.prototype.removeDropper = function () {
    if (this.temp.$dropper) {
      this.temp.$dropper.remove();
      this.temp.$dropper = null;
    }
    $("body").removeClass("easy-calendar__body--no-select");
  };
  ExternalDnD.prototype.showDroppableAreas = function (task) {
    this.droppableWeekAreaBuilder = this.main.scheduler.templates.classBuilder("week_date_class", function (date/*, today */) {
      if (task.dateInDuration(date) && !(date < new Date)) {
        return "easy-calendar__day-cell--droppable";
      } else {
        return "easy-calendar__day-cell--non_droppable";
      }
    });
    this.droppableMonthAreaBuilder = this.main.scheduler.templates.classBuilder("month_date_class", function (date/*, today */) {
      if (task.dateInDuration(date) && !(date < new Date)) {
        return "easy-calendar__month-cell--droppable";
      } else {
        return "easy-calendar__month-cell--non_droppable";
      }
    });
    this.main.repainter.repaintCalendar(true);
  };
  ExternalDnD.prototype.hideDroppableAreas = function () {
    this.main.scheduler.templates.removeClassBuilder("week_date_class", this.droppableWeekAreaBuilder);
    this.main.scheduler.templates.removeClassBuilder("month_date_class", this.droppableMonthAreaBuilder);
    this.main.repainter.repaintCalendar(true);
  };
  /**
   * @param {Task} task
   * @param {int|Object} dateValue
   * @param {boolean} extend
   */
  ExternalDnD.prototype.updateDroppedTask = function (task, dateValue, extend) {
    var main = this.main;
    var temp = this.temp;
    var restMillis = temp.restMillis;
    var scheduler = this.main.scheduler;
    var dropped = this.temp.droppedEvents;
    if (!dateValue) {
      if (dropped) {
        temp.droppedDate = 0;
        for (var i = 0; i < dropped.length; i++) {
          scheduler.deleteEvent(dropped[i].id, true);
        }
        if (dropped.length) {
          this.main.repainter.repaintCalendar(false);
          temp.droppedEvents = [];
        }
      }
      return;
    }
    // var dayView = main.scheduler._mode === "day" || main.scheduler._mode === "week";
    if (temp.droppedDate === dateValue && extend === temp.droppingExtend) return;
    temp.droppingExtend = extend;
    temp.droppedDate = dateValue;
    var empty;
    var dates = [];
    var firstOne = true;
    while ((empty = scheduler.findNextEmptySpace(dateValue, temp.empties)) && (firstOne || extend)) {
      if (!firstOne) {
        var day = new Date(empty.start).getDay();
        if (temp.assignee.working_days.indexOf(day) === -1) {
          dateValue = empty.end;
          continue;
        }
      } else if (restMillis <= 0) {
        dates.push(dateValue);
        dates.push(dateValue + 2 * 60 * 60 * 1000);
        break;
      }
      if (empty.end - empty.start < restMillis) {
        dates.push(empty.start);
        dates.push(empty.end);
        restMillis -= empty.end - empty.start;
        dateValue = empty.end;
        firstOne = false;
      } else {
        dates.push(empty.start);
        dates.push(empty.start + restMillis);
        break;
      }
    }
    // console.log(dates.map(function (value) { return new Date(value); }));
    for (i = 0; i < dates.length; i += 2) {
      var event = dropped[i / 2];
      var startDate = dates[i];
      var endDate = dates[i + 1];
      if (event) {
        event.start_date = new Date(startDate);
        event.end_date = new Date(endDate);
        scheduler.callEvent("onEventChanged", [event.id, event]);
        main.eventBus.fireEvent("eventChanged", event);
        main.repainter.repaintCalendar(false);
        // EasyCalendar.main.log.debug("updateEvent","updateDropper");
      } else {
        var id = scheduler.addEvent(new Date(startDate), new Date(endDate), task.subject, null, {
          issue_id: task.id,
          user_id: this.temp.assignee.id,
          deletable: true,
          type: "allocation",
          _created: true
        });
        dropped.push(scheduler.getEvent(id));
      }
    }
    var del = false;
    for (i = dropped.length - 1; i >= dates.length / 2; i--) {
      del = true;
      scheduler.deleteEvent(dropped.pop().id, true);
    }
    if (del) {
      this.main.repainter.repaintCalendar(false);
    }
  };

  EasyCalendar.ExternalDnD = ExternalDnD;
})();
