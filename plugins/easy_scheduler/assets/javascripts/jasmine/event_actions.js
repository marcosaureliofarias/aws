xdescribe("Event actions", function () {
  function clickOnMenuItem(name){
    $(".easy-calendar__event-icons").show();
    jasmineHelper.clickOn(name);
  }

  beforeAll(function () {
    /** @type {CalendarMain} */
    this.main = easyScheduler;
    this.helper = this.main.tests;
    this.scheduler = this.main.scheduler;
    jasmineHelper.initPageMatchers();
    this.helper.setView("2018-10-16", "week");
  });
  beforeEach(function () {
    this.scheduler.unselect();
  });
  describe("link", function () {
    it("open new tab", function () {
      jasmineHelper.clickOn("[event_id='7337']");
      expect(".easy-calendar__event-icons").toExistsOnPage();
      expect($(".ui-dialog-titlebar").text()).toContain(this.main.settings.labels.entityTitle.allocation);
      spyOn(window, "open");
      clickOnMenuItem(".icon_link");
      expect(window.open).toHaveBeenCalledWith("/issues/3", "_blank");
    });
  });
  describe("delete", function () {
    var event;
    it("delete event and restore", function () {
      event = this.scheduler.getEvent(7340);
      var copy = EasyGem.extend({}, event);
      expect("[event_id='7340']").toExistsOnPage();
      jasmineHelper.clickOn("[event_id='7340']");
      clickOnMenuItem(".icon_delete");
      expect("[event_id='7340']").not.toExistsOnPage();
      this.scheduler.addEvent(event.start_date, event.end_date, event.text, event.id, event);
      expect("[event_id='7340']").toExistsOnPage();
      event = this.scheduler.getEvent(7340);
      expect(event).toEqual(jasmine.objectContaining(copy));
      copy.issue_id = 4326143514;
      expect(event).not.toEqual(jasmine.objectContaining(copy));

    });
  });
  describe("delete further", function () {
    it("delete further", function () {
      expect("[event_id='7338']").toExistsOnPage();
      expect(".dhx_cal_event").toExistsTimes(10);
      jasmineHelper.clickOn("[event_id='7338']");
      clickOnMenuItem(".icon_delete_further");
      expect("[event_id='7340']").not.toExistsOnPage();
      expect(".dhx_cal_event").toExistsTimes(6);
    });
  });
/*  describe("make room", function () {
    it("on limit", function () {
      var eventCount = document.getElementsByClassName("dhx_cal_event").length;
      var id = this.scheduler.addEvent("2018-10-16 11:00", "2018-10-16 12:00", "cod", null, {
        issue_id: 2,
        user_id: 1,
        type: "allocation"
      });
      var selector = "[event_id='" + id + "']";
      expect(selector).toExistsOnPage();
      var element = document.querySelector(selector);
      var box = element.getBoundingClientRect();
      jasmineHelper.mouseEvent("click", box.right - 10, box.top + 10).dispatchEvent(element);
      clickOnMenuItem(".icon_make_room");
      expect(this.scheduler.getEvent(7386).end_date).toEqual(new Date("2018-10-16 11:00"));
      expect(this.scheduler.getEvent(7336).start_date).toEqual(new Date("2018-10-16 12:00"));
      this.scheduler.unselect();
      expect(".dhx_cal_event").toExistsTimes(eventCount + 1);
    });
    it("on middle", function () {
      var eventCount = document.getElementsByClassName("dhx_cal_event").length;
      var id = this.scheduler.addEvent("2018-10-17 10:00", "2018-10-17 11:00", "cod", null, {
        issue_id: 2,
        user_id: 1,
        type: "allocation"
      });
      var selector = "[event_id='" + id + "']";
      expect(selector).toExistsOnPage();
      var element = document.querySelector(selector);
      var box = element.getBoundingClientRect();
      jasmineHelper.mouseEvent("click", box.right - 10, box.top + 10).dispatchEvent(element);
      clickOnMenuItem(".icon_make_room");
      expect(this.scheduler.getEvent(7337).end_date).toEqual(new Date("2018-10-17 10:00"));
      this.scheduler.unselect();
      expect(".dhx_cal_event").toExistsTimes(eventCount + 2);
    });
  });*/
  describe("readonly", function () {
    beforeAll(function () {
      this.helper.setView("2018-03-04", "week");
    });
    it("can't delete", function () {
      var id = 6744;
      expect("[event_id='" + id + "']").toExistsOnPage();
      jasmineHelper.clickOn("[event_id='" + id + "']");
      expect(".icon_delete").not.toExistsOnPage();
      jasmineHelper.clickOn(".ui-dialog-titlebar-close");
    });
  })
});
