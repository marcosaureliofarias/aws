EasyCalendar.schedulerSettings.taskType = 'issues'
EasyCalendar.schedulerSettings.paths.user_allocation_data_path = "/plugin_assets/easy_scheduler/data/jasmine/events.json";
EasyCalendar.schedulerSettings.paths.tasksDataPath = "/plugin_assets/easy_scheduler/data/jasmine/tasks.json";
EasyCalendar.schedulerSettings.paths.meetingFeed = "/plugin_assets/easy_scheduler/data/jasmine/meetings.json";
EasyCalendar.schedulerSettings.noSave = true;
jasmineHelper.lock("meetings");
describe("Common", function () {
  jasmineHelper.unlockOnPass("meetings", function () {
    if (!window.easyScheduler) return;
    var keys = Object.keys(easyScheduler.scheduler._events).join(" ");
    return keys.indexOf("easy_meeting-") > -1;
  });
  beforeAll(function () {
    this.main = easyScheduler;
    this.scheduler = this.main.scheduler;
    this.helper = this.main.tests;
  });
  beforeEach(jasmineHelper.initPageMatchers);
  describe("tasks", function () {
    it("11 tasks", function () {
      expect(this.main.taskData.tasks.length).toBe(11);
    });
    it("8 visible tasks", function () {
      expect(".easy-calendar__task:visible").toExistsTimes(8);
    });
    it("last task estimated", function () {
      var last = easyScheduler.taskData.tasks[easyScheduler.taskData.tasks.length - 1];
      expect(last).toBeDefined();
      expect(last.estimated_hours).toBe(4);
      expect(last.spent_hours).toBe(0);
      expect(last.getRestEstimated()).toBe(2.5);
    });
    it("first task estimated", function () {
      var first = easyScheduler.taskData.tasks[0];
      expect(first).toBeDefined();
      expect(first.estimated_hours).toBe(50);
      expect(first.spent_hours).toBe(10);
      var used = 0;
      var events = easyScheduler.scheduler._events;
      for (var eventId in events) {
        if (!events.hasOwnProperty(eventId)) continue;
        var event = events[eventId];
        if (event.issue_id === first.id) {
          used += (event.end_date - event.start_date) / 3600000;
        }
      }
      expect(first.getRestEstimated()).toBe(50 - 10 - used);
    });
  });
  describe("events", function () {
    beforeAll(function () {
      this.helper.setView("2018-02-06", "week");
    });
    it("set currentView", function () {
      expect(this.scheduler._min_date.toDateString()).toEqual(new Date("2018-02-05").toDateString());
    });
    it("show 4 tasks", function () {
      expect(".easy-calendar__issue").toExistsTimes(4);
    });
    it("show 5 meetings", function () {
      expect(".easy-calendar__meeting").toExistsTimes(5);
    });
    it("show 1 holiday", function () {
      expect(".easy-calendar__attendance").toExistsTimes(1);
    });
    it("show 1 sales activity", function () {
      expect(".easy-calendar__entity-activity").toExistsTimes(1);
    });
    it("show 11 events", function () {
      var self = this;
      var elements = $(".dhx_cal_event,.dhx_cal_event_line");
      expect(elements.length).toBe(11);
      elements.each(function () {
        var id = this.getAttribute("event_id");
        var event = self.scheduler.getEvent(id);
        expect(event.start_date).toBeGreaterThan(self.scheduler._min_date);
        expect(event.end_date).toBeLessThan(self.scheduler._max_date);
      });
    });
  });
  describe("drag", function () {
    beforeAll(function () {
      const todayForward = new Date;
      const todayBack = new Date;
      this.helper.setView(todayForward, "week");
      if (jasmineHelper.hasTag("manager")) {
        jasmineHelper.clickOn(".easy-calendar__assignee[data-user_id=\"1\"]");
      }
      const task = easyScheduler.taskData.tasks[1];
      const daysForward = new Date(todayForward.setDate(todayForward.getDate() + 15));
      const daysBack = new Date(todayBack.setDate(todayBack.getDate() - 15));
      task.start_date = daysBack;
      task.due_date = daysForward;
    });
    function outOfRangeTest(day, helper) {
      helper.setView(day, "week");
      // expect(".easy-calendar__issue").toExistsTimes(3);
      var anchorOffset = $('.dhx_scale_hour[aria-label="10"]').offset();
      const posX = anchorOffset.left + 50;
      const posY = anchorOffset.top + 10;
      const task = document.getElementsByClassName("easy-calendar__task")[1];
      const body = document.body;
      jasmineHelper.mouseEvent("mousedown", 431, 208).dispatchEvent(task);
      jasmineHelper.mouseEvent("mousemove", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__dropper").toExistsOnPage();
      jasmineHelper.mouseEvent("mouseup", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__issue").toExistsTimes(0);
    }
    it("DnD out of range before", function () {
      const today = new Date;
      const beforeStart = new Date(today.setDate(today.getDate() - 60));
      outOfRangeTest(beforeStart, this.helper);
    });

    it("DnD out of range after", function () {
      const today = new Date;
      const afterFinish = new Date(today.setDate(today.getDate() + 60));
      outOfRangeTest(afterFinish, this.helper);
    });

    it("DnD in range", function () {
      const today = new Date;
      const inRange = new Date(today.setDate(today.getDate() + 7));
      this.helper.setView(inRange, "week");
      var anchorOffset = $('.dhx_scale_hour[aria-label="10"]').offset();
      const posX = anchorOffset.left + 50;
      const posY = anchorOffset.top + 10;
      const task = document.getElementsByClassName("easy-calendar__task")[1];
      const body = document.body;
      jasmineHelper.mouseEvent("mousedown", 431, 208).dispatchEvent(task);
      jasmineHelper.mouseEvent("mousemove", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__dropper").toExistsOnPage();
      jasmineHelper.mouseEvent("mouseup", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__issue").toExistsTimes(5);
    });
    function toJSONLocal (date) {
      const local = new Date(date);
      local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
      return local.toJSON().slice(0, 10);
    }
    // it("DnD create allocations", function () {
    //   const today = new Date;
    //   const inRange = new Date(today.setDate(today.getDate() + 7));
    //   this.helper.setView(inRange, "week");
    //   const weekStart = this.helper.main.scheduler.date.week_start(inRange);
    //   const targets = [];
    //   let target = {};
    //   for (let i = 0; i < 5; i++) {
    //     if (i === 0) {
    //       target = {
    //         start: new Date(new Date().setDate(weekStart.getDate() + i)).setHours(10, 0, 0, 0),
    //         end: new Date(new Date().setDate(weekStart.getDate() + i)).setHours(16,  30,0, 0)
    //       };
    //     } else {
    //       target = {
    //         start: new Date(new Date().setDate(weekStart.getDate() + i)).setHours(8,0,0,0),
    //         end: new Date(new Date().setDate(weekStart.getDate() + i)).setHours(16,30,0,0)
    //       };
    //     }
    //     targets.push(target);
    //   }
    //   var events = easyScheduler.scheduler.get_visible_events();
    //   var newEvents = events.filter(function (event) {
    //     return event.id > 1e12;
    //   }).sort(function (a, b) {
    //     return a.start_date - b.start_date;
    //   });
    //   expect(targets.length).toBe(newEvents.length);
    //   for (var i = 0; i < targets.length; i++) {
    //     expect(newEvents[i].start_date).toEqual(new Date(targets[i].start));
    //     expect(newEvents[i].end_date).toEqual(new Date(targets[i].end));
    //   }
    // });
    afterAll(function () {
      if (jasmineHelper.hasTag("manager")) {
        jasmineHelper.clickOn(".easy-calendar__assignee[data-user_id=\"24\"]");
      }
    });
  });
  xdescribe("modal", function () {
    beforeAll(function () {
      this.helper.setView("2018-03-27", "week");
    });
    it("show event 6742", function () {
      expect("div[event_id='6742'").toExistsOnPage();
    });
    it("open modal by edit icon", function () {
      // noinspection JSJQueryEfficiency
      jasmineHelper.clickOn("div[event_id='6742']");
      // noinspection JSJQueryEfficiency
      $($("div[event_id=6742]")[1]).find(".icon_details").click();
      expect("#calendar_modal:visible").toExistsOnPage();
      jasmineHelper.clickOn(".ui-dialog-titlebar-close");
      expect("#calendar_modal:visible").not.toExistsOnPage();
    });
    it("change by modal", function (done) {
      var fxOff = $.fx.off;
      $.fx.off = true;
      var event = this.scheduler.getEvent(6742);
      $("div[event_id=" + event.id + "]").contextmenu();
      EasyGem.schedule.require(function () {
        var $modal = $("#calendar_modal");
        $modal.find("#allocation_issue_id").val(event.issue_id);
        $modal.find(".ui-datepicker-trigger").click();
        $("#ui-datepicker-div").find(".ui-datepicker-current-day").next().click();
        $modal.find("[name='allocation_start_time']").val("09:00");
        $modal.find("[name='allocation_end_time']").val("12:30");

        jasmineHelper.clickOn("#calendar_modal_button_save");
        expect("#calendar_modal:visible").not.toExistsOnPage();
        expect(event).toBeDefined();
        expect(event.start_date).toEqual(new Date("2018-03-28 09:00"));
        expect(event.end_date).toEqual(new Date("2018-03-28 12:30"));
        $.fx.off = fxOff;
        done();
      }, function () {
        var $modal = $("#calendar_modal");
        return $modal.parent().find("#calendar_modal_button_save").length && $modal.find(".ui-datepicker-trigger").length;
      });
    });
  });
  describe("selected+primary from storage", function () {
    var getIds = function (array) {
      return array.map(function (user) {
        return user.id
      });
    };
    beforeEach(function () {
      this.assData = this.main.assigneeData;
      this.temp = {
        selected: this.assData.selectedAssignees,
        primaryId: this.assData.primaryId,
        currentId: this.assData.currentId,
        storage: this.main.tests.fakeStorage
      };
      /**
       * @param {Array.<int>} selected
       * @param {int} primary
       */
      this.setFakeStorage = function (selected, primary) {
        this.main.tests.fakeStorage = {
          "primary-assignee": primary.toString(),
          "selected-assignees": JSON.stringify(selected)
        }
      };
      this.assData.currentId = 1;
      this.assData.primaryId = 1;
      this.assData.selectedAssignees = [];
    });
    it("load faked selected ids", function () {
      this.setFakeStorage([265, 45], 45);
      expect(this.assData.savedAssigneeIds()).toEqual([265, 45, 1]);
    });
    it("load faked primary ID", function () {
      this.setFakeStorage([265, 45], 45);
      expect(this.scheduler.getFromStorage("primary-assignee")).toEqual((45).toString());
    });
    describe("load()", function () {
      it("handle empty selected", function () {
        this.setFakeStorage([], 45);
        this.assData.load([]); // already loaded from file
        expect(getIds(this.assData.selectedAssignees)).toEqual([1]);
      });
      if (jasmineHelper.hasTag("manager")) {
        it("handle mismatched selected and primary", function () {
          this.setFakeStorage([24], 25);
          this.assData.load([]);
          expect(getIds(this.assData.selectedAssignees)).toEqual([1, 24]);
          expect(this.assData.primaryId).toEqual(1);
        });
      }
      it("handle unloaded assignee", function () {
        this.setFakeStorage([24, 25648], 25);
        this.assData.load([]);
        expect(getIds(this.assData.selectedAssignees)).toEqual([1, 24]);
      });
      it("handle correct selected", function () {
        this.setFakeStorage([1, 24, 25], 1);
        this.assData.load([]);
        expect(getIds(this.assData.selectedAssignees)).toEqual([1, 24, 25]);
        expect(this.assData.primaryId).toEqual(1);
      });
      if (jasmineHelper.hasTag("manager")) {
        it("handle correct selected and primary", function () {
          this.setFakeStorage([24, 25], 25);
          this.assData.load([]);
          expect(getIds(this.assData.selectedAssignees)).toEqual([1, 24, 25]);
          expect(this.assData.primaryId).toEqual(25);
        });
      }
    });
    afterEach(function () {
      this.assData.selectedAssignees = this.temp.selected;
      this.assData.primaryId = this.temp.primaryId;
      this.assData.currentId = this.temp.currentId;
      this.main.tests.fakeStorage = this.temp.storage;
    });
  });
  describe("task-less allocation", function () {
    beforeAll(function () {
      this.helper.setView("2018-04-19", "week");
    });
    it("show", function () {
      expect("[event_id='7400']").toExistsOnPage();
      var $event = $("[event_id='7400']");
      expect($event.text()).toContain(this.main.settings.labels.entityTitle.allocation);
      expect(this.scheduler.getEvent(7400).readonly).toBeTruthy();
    });
  });
});
