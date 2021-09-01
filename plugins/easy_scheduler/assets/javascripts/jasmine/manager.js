jasmineHelper.lock("meetings");
describe("Manager with mocked data", function () {
  "use strict";

  beforeAll(function () {
    this.main = easyScheduler;
    this.scheduler = this.main.scheduler;
    this.helper = this.main.tests;
  });
  beforeEach(jasmineHelper.initPageMatchers);
  it("should load", function () {
    expect(true).toBeTruthy();
  });
  describe("change primary",function () {
    beforeAll(function () {
      this.assigneeData = this.helper.main.assigneeData;
    });
    it("change to Admin",function () {
      expect(this.assigneeData.primaryId).toEqual(24);
      jasmineHelper.clickOn(".easy-calendar__assignee[data-user_id=\"1\"]");
      expect(this.assigneeData.primaryId).toEqual(1);
    });
    it("change to Reggie",function () {
      expect(this.assigneeData.primaryId).toEqual(1);
      jasmineHelper.clickOn(".easy-calendar__assignee[data-user_id=\"24\"]");
      expect(this.assigneeData.primaryId).toEqual(24);
    });
    afterAll(function () {
      this.assigneeData.setPrimary(this.assigneeData.getAssigneeById(24));
    });
  });
  describe("DnD",function () {
    beforeAll(function () {
      var index = 0;
      this.task = this.main.taskData.tasks[index];
      const daysForward = new Date(new Date().setDate(new Date().getDate() + 15));
      const daysBack = new Date(new Date().setDate(new Date().getDate() - 15));
      const inRange = new Date(new Date().setDate(new Date().getDate() + 7));
      this.task.start_date = daysBack;
      this.task.due_date = daysForward;
      this.helper.setView(inRange, "week");
      this.taskElement =  document.getElementsByClassName("easy-calendar__task")[index];
    });
    it("first task contains",function () {
      expect($(this.taskElement).text()).toEqual(jasmine.stringMatching(this.task.subject));
    });
    it("change Assignee", function () {
      var body = document.body;
      var startOffset = $(this.taskElement).offset();
      var startX = startOffset.left + 10;
      var startY = startOffset.top + 10;
      var anchorOffset = $('.dhx_scale_hour[aria-label="11"]').offset();
      var posX = anchorOffset.left + 50;
      var posY = anchorOffset.top + 10;
      jasmineHelper.mouseEvent("mousedown", startX, startY).dispatchEvent(this.taskElement);
      jasmineHelper.mouseEvent("mousemove", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__dropper").toExistsOnPage();
      expect(this.task.getRestEstimated()).toEqual(0);
      jasmineHelper.mouseEvent("mouseup", posX, posY).dispatchEvent(body);
      expect(this.task.assigned_to_id).toEqual(this.task.assigned_to_id);
      expect(".easy-calendar__issue").toExistsTimes(4);
      expect(this.task.getRestEstimated()).toEqual(0);
    });
    it("cancel", function () {
      var oldAssigneeId = this.task.assigned_to_id;
      var body = document.body;
      var startOffset = $(this.taskElement).offset();
      var startX = startOffset.left + 10;
      var startY = startOffset.top + 10;
      var anchorOffset = $('.dhx_scale_hour[aria-label="11"]').offset();
      var posX = anchorOffset.left + 50;
      var posY = anchorOffset.top + 10;
      jasmineHelper.mouseEvent("mousedown", startX, startY).dispatchEvent(this.taskElement);
      jasmineHelper.mouseEvent("mousemove", posX, posY).dispatchEvent(body);
      expect(".easy-calendar__dropper").toExistsOnPage();
      jasmineHelper.mouseEvent("mousemove", startX, startY).dispatchEvent(body);
      jasmineHelper.mouseEvent("mouseup", startX, startY).dispatchEvent(body);
      expect(this.task.assigned_to_id).toEqual(oldAssigneeId);
    });
  })
});
