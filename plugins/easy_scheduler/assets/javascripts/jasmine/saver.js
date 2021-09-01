describe("Saver", function () {
  var noop = function () {
  };
  var paths = {
    taskPath: "",
    meeting_path: "",
    easy_attendance_path: "",
    easy_entity_activity_path: "",
    save_allocation_path: ""
  };
  var templates = {
    taskSaveLog: "{{id}}|{{subject}}|{{assigneeName}}"
  };
  var labels = {
    everythingSaved: "TEST Everything saved",
    saveFailed: "Save failed"
  };
  var settings = {paths: paths, templates: templates, labels: labels};
  var utils = {
    messages: [],
    showError: function (text) {
      this.messages.push(text);
    },
    objectValues: function (object) {
      return Object.keys(object).map(function (key) {
        return object[key];
      });
    }
  };
  utils.showNotice = utils.showError;
  utils.showLastSaveAtMsg = utils.showError;
  var taskData = {
    tasks: [],
    taskMap: {'issues': {}},
    taskType: 'issues',
    add: function (task) {
      this.tasks.push(task);
      this.taskMap['issues'][task.id] = task;
    },
    getTaskById: function (id) {
      return this.taskMap['issues'][id];
    }
  };
  var assigneeData = {
    assigneeMap: {},
    getAssigneeById: function (id) {
      return this.assigneeMap[id];
    }, add: function (assignee) {
      this.assigneeMap[assignee.id] = assignee;
    }
  };
  var events = {};
  var loader = { load: noop, reload: noop };
  var eventBus = { register: noop, fireEvent: noop };
  var mainSource = {
    settings: settings,
    loader: loader,
    taskData: taskData,
    assigneeData: assigneeData,
    scheduler: {_events: events},
    eventBus: eventBus,
    utils: utils
  };
  //####################################################################################################################
  beforeEach(function () {
    this.main = $.extend(true, {}, mainSource);
    this.saver = new EasyCalendar.Saver(this.main);
    var utiles = new EasyCalendar.Utils(this.main);
    this.main.utils = $.extend(true, utiles, this.main.utils);
    for (var i = 0; i < 3; i++) {
      var assignee = new EasyCalendar.Assignee(this.main, { id: i, name: "Test assignee " + i });
      this.main.assigneeData.add(assignee);
    }
    this.ajax = spyOn($, "ajax");
  });
  it("init", function () {
    expect(this.saver).toBeDefined();
    expect(this.saver.progress).toEqual(jasmine.objectContaining({
      savingTimeout: 0,
      events: null,
      deletedTypedEvents: null,
      taskChanges: [],
      deletedEvents: [],
      promise: null
    }));
  });
  describe("tasks", function () {
    beforeEach(function () {
      var task = new EasyCalendar.Issue(this.main);
      task.update({
        id: 1256,
        subject: "Test task 5",
        _changed: true,
        assigned_to_id: 2,
        testValue: 8,
        _old: {testValue: 5, assigned_to_id: 3}
      });
      this.task = task;
      this.main.taskData.add(task)
    });
    // fixme ajax is async, we have to wait for it
    xit("fail", function () {
      var reason = "TEST failed TEST";
      this.ajax.and.returnValue($.Deferred().reject({
        responseText: JSON.stringify({errors: [reason]})
      }));
      this.saver.save();
      var result = this.main.utils.messages[0];
      var jsm = jasmine.stringMatching;
      expect(result).toEqual(jsm(mainSource.settings.labels.saveFailed));
      expect(result).toEqual(jsm(reason));
    });
  });
  describe("generic meetings", function () {
    beforeEach(function () {
      this.main.scheduler.isOneDayEvent = easyScheduler.scheduler.isOneDayEvent;
      this.main.meetings = {main: this.main, createMeeting: easyScheduler.meetings.createMeeting};
    });

    describe("meetings", function () {
      beforeEach(function () {
        var meeting = this.main.meetings.createMeeting({
          id: "easy_meeting-256",
          name: "Test meeting 5",
          eventType: "meeting",
          start: "2018-05-28T10:00",
          end: "2018-05-28T16:00"
        });
        meeting._changed = true;
        this.meeting = meeting;
        this.main.scheduler._events[meeting.id] = meeting;
      });
      // fixme ajax is async, we have to wait for it
      xit("success", function () {
        this.ajax.and.returnValue($.Deferred().resolve());
        this.saver.save();
        expect(this.ajax).toHaveBeenCalled();
      });
      // fixme ajax is async, we have to wait for it
      xit("fail", function () {
        var reason = "TEST failed TEST";
        this.ajax.and.returnValue($.Deferred().reject({
          responseText: JSON.stringify({errors: [reason]})
        }));
        this.saver.save();
        expect(this.ajax).toHaveBeenCalled();
        var result = this.main.utils.messages[0];
        var jsm = jasmine.stringMatching;
        expect(result).toEqual(jsm(mainSource.settings.labels.saveFailed));
        expect(result).toEqual(jsm(reason));
      });
    });
  });
  describe("allocations", function () {
    beforeEach(function () {
      var task = new EasyCalendar.Issue(this.main);
      task.update({
        id: 1256,
        subject: "Test task 5",
        assigned_to_id: 2,
        testValue: 8
      });
      this.task = task;
      this.main.taskData.add(task);
      this.allocation = {
        id: 256,
        issue_id: 1256,
        start_date: new Date("2018-05-06 15:00"),
        end_date: new Date("2018-05-06 16:30"),
        text: task.subject,
        type: "allocation",
        _changed: true
      };
      this.main.scheduler._events[this.allocation.id] = this.allocation;
    });
    // fixme ajax is async, we have to wait for it
    xit("success", function () {
      this.ajax.and.returnValue($.Deferred().resolve());
      this.saver.save();
      expect(this.ajax).toHaveBeenCalled();
    });
    // fixme ajax is async, we have to wait for it
    xit("fail", function () {
      var reason = "TEST failed TEST";
      this.ajax.and.returnValue($.Deferred().reject({
        responseText: JSON.stringify({errors: [reason]})
      }));
      this.saver.save();
      expect(this.ajax).toHaveBeenCalled();
      var result = this.main.utils.messages[0];
      var jsm = jasmine.stringMatching;
      expect(result).toEqual(jsm(mainSource.settings.labels.saveFailed));
      expect(result).toEqual(jsm(reason));
    });
    // fixme ajax is async, we have to wait for it
    xit("structured fail", function () {
      var response = {
        issue_id:this.task.id,
        allocations:[{date:moment(this.allocation.start_date).format("YYYY-MM-DD"),reason:"TEST_reason"}]};
      var expected = "Test task 5 allocation at 2018-05-06 failed because of TEST_reason";
      this.ajax.and.returnValue($.Deferred().reject({
        responseText: JSON.stringify({errors: [response]})
      }));
      this.saver.save();
      expect(this.ajax).toHaveBeenCalled();
      var result = this.main.utils.messages[0];
      var jsm = jasmine.stringMatching;
      expect(result).toEqual(jsm(mainSource.settings.labels.saveFailed));
      expect(result).toEqual(jsm(expected));
    });
  });
});
