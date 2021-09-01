xdescribe("Tasks", function () {
  beforeAll(function () {
    this.main = easyScheduler;
    this.scheduler = this.main.scheduler;
    this.helper = this.main.tests;
    this.ajax = spyOn($, "ajax");
  });
  beforeEach(jasmineHelper.initPageMatchers);
  xdescribe("Modal", function () {
    it("first", function () {
      var task = this.main.taskData.tasks[0];
      this.ajax.and.returnValue($.Deferred().reject({
        responseText: JSON.stringify({task})
      }));
      var $element = $(".easy-calendar__task").first();
      $element.trigger("no_drag_task_click", jasmineHelper.clickOn($element));
      expect("#calendar_modal").toExistsOnPage();
      var $modal = $("#calendar_modal");
      var text = $modal.text();
      expect(text).toEqual(jasmine.stringMatching("Easy Admin"));
      expect(text).toEqual(jasmine.stringMatching("Tim Junior"));
      expect(text).toEqual(jasmine.stringMatching(task.subject));
      expect(text).toEqual(jasmine.stringMatching("Dartlang"));
      jasmineHelper.clickOn(".ui-dialog-titlebar-close");
    });
  });
});
