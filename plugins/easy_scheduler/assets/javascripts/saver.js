(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {CalendarMain} main
   * @property {{savingTimeout: int,
   *   events:Object|null,
   *   deletedTypedEvents: Object|null,
   *   promise:Deferred|null}} progress
   * @property {Array.<string>} locks
   */
  function Saver(main) {
    this.main = main;
    this.initObserver();
    this.locks = [];
    this.resetProgress();
  }

  /**
   * @methodOf Saver
   */
  Saver.prototype.resetProgress = function () {
    this.progress = {
      savingTimeout: 0,
      events: null,
      deletedTypedEvents: null,
      taskChanges: [],
      deletedEvents: [],
      promise: null
    };
  };

  Saver.prototype.save = function () {
    var self = this;
    const deletedEvents = self.progress.deletedEvents[0];
    const isRecurring = deletedEvents ? deletedEvents._isRecurring : false;
    this.progress.promise = this.saveTasks()
        .then(this.saveMeetings.bind(this))
        .then(this.saveAttendances.bind(this))
        .then(this.saveSalesActivities.bind(this))
        .then(this.saveAllocations.bind(this))
        .then(function (text) {
          if (self.main.settings.noSave || isRecurring) {
            return self.main.loader.reload();
          }
          // self.main.utils.showLastSaveAtMsg(text);
          return self.main.loader.reload(); // uncomment if fresh data is necessary after save
        })
        .fail(function (notices) {
          self.main.utils.showError("Save failed :<br>" + notices.join("<br>"));
          self.main.loader.reload();
        })
        .always(function () {
          self.makeUnchanged();
          self.resetProgress();
        });
  };
  /**
   * @return {Deferred}
   */
  Saver.prototype.saveTasks = function () {
    var tasksData = this.prepareTasks();
    var self = this;
    var fails = [];
    var taskPromises = tasksData.map(function (taskData) {
      return self.saveOneTask(taskData, fails);
    });
    return $.when.apply(null, taskPromises).then(function () {
      if (fails.length) {
        return self.parseMultipleErrors(fails);
      } else {
        self.progress.taskChanges = Array.prototype.slice.call(arguments);
      }
    });
  };
  Saver.prototype.prepareTaskSaveLog = function (taskData) {
    var task = this.main.taskData.getTaskById(taskData.id);
    var obj = $.extend({subject: task.subject}, taskData);
    if (obj.assigned_to_id) {
      obj.assigneeName = this.main.assigneeData.getAssigneeById(obj.assigned_to_id).name;
    }
    return Mustache.render(this.main.settings.templates.taskSaveLog, obj);
  };
  /**
   * @param {{id:int}} taskData
   * @param {Array.<String>} fails
   * @return {Deferred}
   */
  Saver.prototype.saveOneTask = function (taskData, fails) {
    const log = this.prepareTaskSaveLog(taskData);
    if (this.main.settings.noSave) return log;
    const url = this.main.settings.paths.taskPath.replace("__taskId", taskData.id);
    delete taskData.id;
    let data = {};
    const paramsKey = taskData.params_key;
    if (!!taskData.assigned_to_id && paramsKey === "issue") {
      data.validate_assignee = true;
    }
    delete taskData.params_key;
    data[paramsKey] = taskData;
    let defer = $.Deferred();
    $.ajax({
      url: url,
      dataType: "text",
      method: "PUT",
      data: JSON.stringify(data),
      beforeSend: function (xhr) {
        xhr.setRequestHeader("Content-type", "application/json");
        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
      }
    })
        .fail(function (xhr) {
          fails.push(xhr);
        }).always(function () {
          defer.resolve(log);
        }
    );
    return defer;
  };
  Saver.prototype.saveMeetings = function () {
    var data = this.prepareMeetings();
    var url = this.main.settings.paths.meeting_path;
    return $.when(
        this.saveGenericMeetings(data, url, "easy_meeting"),
        this.deleteGenericMeetings(this.getDeletedEventsByType("meeting"), url));
  };
  Saver.prototype.saveAttendances = function () {
    var data = this.prepareAttendances();
    var url = this.main.settings.paths.easy_attendance_path;
    return $.when(
        this.saveGenericMeetings(data, url, "easy_attendance"),
        this.deleteGenericMeetings(this.getDeletedEventsByType("easy_attendance"), url));
  };
  Saver.prototype.saveSalesActivities = function () {
    var data = this.prepareSalesActivities();
    var url = this.main.settings.paths.easy_entity_activity_path;
    return $.when(
        this.saveGenericMeetings(data, url, "easy_entity_activity"),
        this.deleteGenericMeetings(this.getDeletedEventsByType("easy_entity_activity"), url));
  };
  Saver.prototype.saveGenericMeetings = function (data, urlTemplate, dataKey) {
    var self = this;
    var fails = [];
    var promises = data.map(function (entityData) {
      return self.saveOneGenericMeeting(urlTemplate, entityData, fails, dataKey);
    });
    return $.when.apply(null, promises).then(function () {
      if (fails.length) {
        return self.parseMultipleErrors(fails);
      }
    });
  };
  Saver.prototype.saveOneGenericMeeting = function (urlTemplate, meetingData, fails, dataKey) {
    if (this.main.settings.noSave) return;
    var url = urlTemplate.replace("__entityId", meetingData.id);
    delete meetingData.id;
    var defer = $.Deferred();
    var data = {};
    data[dataKey] = meetingData;
    $.ajax({
      url: url,
      dataType: "text",
      method: "PATCH",
      data: JSON.stringify(data),
      beforeSend: function (xhr) {
        xhr.setRequestHeader("Content-type", "application/json");
        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
      }
    })
        .fail(function (xhr) {
          fails.push(xhr);
        }).always(function () {
          defer.resolve();
        }
    );
    return defer;
  };
  Saver.prototype.saveAllocations = function () {
    var self = this;
    var resources = this.prepareAllocations();
    var allocUrl = this.main.settings.paths.save_allocation_path;
    if (resources.length === 0) return;
    var data = {"issues": resources, "allCustom": true};
    if (this.main.settings.noSave) return;
    var xhr = $.ajax({
      url: allocUrl,
      dataType: "text",
      method: "POST",
      data: JSON.stringify(data),
      beforeSend: function (xhr) {
        xhr.setRequestHeader("Content-type", "application/json");
        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
      }
    });
    return xhr
    /** .fail cannot be here because all chained .fail gets primary reject value, not updated one */
        .then(null, function (xhr) {
          var text = xhr.responseText;
          if (text.substring(0, 1) === "{") {
            var json = JSON.parse(text);
            var notices = [];
            for (var i = 0; i < json.errors.length; i++) {
              var error = json.errors[i];
              var issue = self.main.taskData.getTaskById(error.issue_id);
              if (issue) {
                for (var j = 0; j < error.allocations.length; j++) {
                  var alloc = error.allocations[j];
                  notices.push(issue.subject + " allocation at " + alloc["date"] + " failed because of " + alloc["reason"]);
                }
              } else {
                notices.push(error);
              }
            }
            return notices;
          }
          return [text];
        });
  };
  Saver.prototype.prepareTasks = function () {
    return this.main.taskData.tasks.filter(/** @param {Task} task*/function (task) {
      return task._changed && task._old
    }).map(function (task) {
      var result = {id: task.id, params_key: task.params_key};
      var changedKeys = Object.keys(task._old);
      for (var i = 0; i < changedKeys.length; i++) {
        var key = changedKeys[i];
        result[key] = task[key];
      }
      $.extend(result, task.extraParams());
      return result;
    })
  };
  Saver.prototype.prepareMeetings = function () {
    var meetings = this.getEventsByType("meeting", true);
    return meetings.map(function (meeting) {
      return {
        id: meeting.realId,
        start_time: meeting.start_date.toString(),
        end_time: meeting.end_date.toString()
      };
    });
  };
  Saver.prototype.prepareAttendances = function () {
    var attendances = this.getEventsByType("easy_attendance", true);
    return attendances.map(function (meeting) {
      return {
        id: meeting.realId,
        arrival: meeting.start_date.toString(),
        departure: meeting.end_date.toString()
      };
    });
  };
  Saver.prototype.prepareSalesActivities = function () {
    var salesActivities = this.getEventsByType("easy_entity_activity", true);
    return salesActivities.map(function (meeting) {
      return {
        id: meeting.realId,
        start_time: meeting.start_date.toString(),
        end_time: meeting.end_date.toString()
      };
    });
  };

  Saver.prototype.prepareAllocations = function () {
    var allocations = this.getEventsByType("allocation", false);
    var taskIds = {};
    for (var i = 0; i < allocations.length; i++) {
      if (!allocations[i]._changed) continue;
      taskIds[allocations[i].issue_id] = true;
    }
    var deletedEvents = this.getDeletedEventsByType("allocation");
    deletedEvents.forEach(function (event) {
      if (event._created) return;
      if (event.issue_id === undefined) return;
      taskIds[event.issue_id] = true;
    });
    return this.main.utils.objectValues(this.main.taskData.taskMap['issues'])
        .filter(function (task) {
          return taskIds[task.id] || task._changed;
        }).map(function (task) {
          return task.toSaveMap(allocations);
        })
  };
  /**
   * @param {Array.<{realId:int}>} entities
   * @param {string} urlTemplate
   * @return {Deferred}
   */
  Saver.prototype.deleteGenericMeetings = function (entities, urlTemplate) {
    var self = this;
    var fails = [];
    var promises = entities.map(function (entity) {
      var defer = $.Deferred();
      if (!entity.realId) return;
      $.ajax({
        url: urlTemplate.replace("__entityId", entity.realId),
        method: "DELETE",
        dataType: "text"
      })
          .fail(function (xhr) {
            fails.push(xhr);
          })
          .always(function () {
            defer.resolve();
          });
      return defer;
    });
    return $.when.apply(null, promises).then(function () {
      if (fails.length) {
        return self.parseMultipleErrors(fails);
      }
    });
  };
  /**
   * @methodOf Saver
   * @param {string} type
   * @param {boolean} changed
   * @return {Array.<Object>}
   */
  Saver.prototype.getEventsByType = function (type, changed) {
    var events = this.progress.events;
    if (!events) {
      events = {};
      this.main.utils.objectValues(this.main.scheduler._events).forEach(function (event) {
        var eventType = event.type;
        if (!events[eventType]) {
          return events[eventType] = [event];
        }
        events[eventType].push(event);
      });
      this.progress.events = events;
    }
    if (!events[type]) return [];
    if (changed) {
      return events[type].filter(function (entity) {
        return entity._changed && !entity._deleted;
      });
    } else {
      return events[type];
    }
  };
  /***
   *
   * @param {number} taskID
   * @returns {*}
   */
  Saver.prototype.getAllocationIdById = function(taskID) {
    var allocation = this.getEventsByType("allocation");
    if (allocation.length === 0) return;
    var allocationID = [];

    this.main.utils.objectValues(allocation).forEach(function (event) {
      if (event.issue_id === taskID){
        allocationID.push(event.id)
      }
    });
    return allocationID;
  };
  /**
   * @methodOf Saver
   * @param {string} type
   * @return {Array.<Object>}
   */
  Saver.prototype.getDeletedEventsByType = function (type) {
    var events = this.progress.deletedTypedEvents;
    if (!events) {
      events = {};
      this.main.utils.objectValues(this.progress.deletedEvents).forEach(function (event) {
        var eventType = event.type;
        if (!events[eventType]) {
          return events[eventType] = [event];
        }
        events[eventType].push(event);
      });
      this.progress.deletedTypedEvents = events;
    }
    if (!events[type]) {
      events[type] = []
    }
    return events[type];
  };
  Saver.prototype.makeUnchanged = function () {
    this.main.taskData.tasks.forEach(function (task) {
      delete task._changed;
      delete task._old
    });
    var events = this.main.scheduler._events;
    var ids = Object.getOwnPropertyNames(events);
    for (var i = 0; i < ids.length; i++) {
      var event = events[ids[i]];
      delete event._changed;
      delete event._created;
    }
  };
  /**
   * @param {Array.<xhr>} fails
   * @return {Deferred}
   */
  Saver.prototype.parseMultipleErrors = function (fails) {
    var notices = [];
    for (var k = 0; k < fails.length; k++) {
      var xhr = fails[k];
      var responseText = xhr.responseText;
      if (responseText.charAt(0) !== "{") {
        notices.push(responseText);
        continue;
      }
      var json = JSON.parse(responseText);
      for (var i = 0; i < json.errors.length; i++) {
        var error = json.errors[i];
        notices.push(error);
      }
    }
    return $.Deferred().reject(notices);
  };
  Saver.prototype.initObserver = function () {
    var self = this;
    self.main.eventBus.register("eventsLoading", function () {
      self.addLock("eventsLoading");
    });
    self.main.eventBus.register("eventsLoaded", function () {
      self.removeLock("eventsLoading");
    });
    self.main.eventBus.register("tasksLoading", function () {
      self.addLock("tasksLoading");
    });
    self.main.eventBus.register("tasksLoaded", function () {
      self.removeLock("tasksLoading");
    });
    self.main.eventBus.register("startExternalDnD", function () {
      self.addLock("externalDnD");
    });
    self.main.eventBus.register("endExternalDnD", function () {
      self.removeLock("externalDnD");
      self.delayedSave();
    });
    self.main.eventBus.register("taskChanged", function () {
      self.delayedSave();
    });
    self.main.eventBus.register("genericMeetingChanged", function (event) {
      if (!event._changed) return;
      self.delayedSave();
    });
    self.main.eventBus.register("schedulerInited", function (scheduler) {
      scheduler.attachEvent("onEventDeleted", function (id, event) {
        event._deleted = true;
        self.progress.deletedEvents.push(event);
      });
    });
  };
  /**
   * @param {string} name
   */
  Saver.prototype.addLock = function (name) {
    if (this.locks.indexOf(name) > -1) return;
    this.locks.push(name);
  };
  /**
   * @param {string} name
   */
  Saver.prototype.removeLock = function (name) {
    var index = this.locks.indexOf(name);
    if (index === -1) return;
    this.locks.splice(index, 1);
  };
  Saver.prototype.delayedSave = function () {
    var self = this;
    if (self.locks.length) return;
    if (self.progress.savingTimeout) {
      window.clearTimeout(self.progress.savingTimeout);
    }
    // console.log("Saving delay started");
    self.progress.savingTimeout = window.setTimeout(function () {
      self.progress.savingTimeout = 0;
      // if (self.progress.savingSuppressed) console.log("Saving suppressed");
      if (self.locks.length) return;
      // console.log("Saving on the way");
      self.save();
    }, 1000);
  };

  EasyCalendar.Saver = Saver;
})();
